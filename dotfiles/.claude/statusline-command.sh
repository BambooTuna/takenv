#!/bin/sh
CACHE_FILE="/tmp/claude-statusline-cache.json"
CACHE_TTL=60

# ISO8601 → 残り時間の人間が読みやすい形式（例: 2.3h, 5d）
format_time_remaining() {
  reset_at="$1"
  now=$(date -u +%s)

  OS=$(uname -s)
  if [ "$OS" = "Darwin" ]; then
    target=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$reset_at" +%s 2>/dev/null)
  else
    target=$(date -u -d "$reset_at" +%s 2>/dev/null)
  fi

  if [ -z "$target" ]; then
    printf "?"
    return
  fi

  diff=$((target - now))
  if [ "$diff" -le 0 ]; then
    printf "0h"
    return
  fi

  hours=$((diff / 3600))
  if [ "$hours" -ge 48 ]; then
    days=$((hours / 24))
    printf "%dd" "$days"
  elif [ "$hours" -ge 1 ]; then
    frac=$(( (diff % 3600) * 10 / 3600 ))
    printf "%d.%dh" "$hours" "$frac"
  else
    mins=$((diff / 60))
    printf "%dm" "$mins"
  fi
}

# 使用率に応じた ANSIカラーコード（0-70%緑, 70-90%黄, 90%+赤）
get_color() {
  pct=$1
  if [ "$pct" -ge 90 ]; then
    printf "\033[31m"
  elif [ "$pct" -ge 70 ]; then
    printf "\033[33m"
  else
    printf "\033[32m"
  fi
}

# キャッシュ読み込み（60秒TTL）
get_cached_data() {
  if [ ! -f "$CACHE_FILE" ]; then
    return 1
  fi

  cache_time=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null)
  now=$(date +%s)
  age=$((now - cache_time))

  if [ "$age" -lt "$CACHE_TTL" ]; then
    cat "$CACHE_FILE"
    return 0
  fi

  return 1
}

# API からレート制限データを取得してキャッシュに保存
fetch_usage_data() {
  TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    return 1
  fi

  RESPONSE=$(curl -s --max-time 3 -X GET \
    "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -H "anthropic-beta: oauth-2025-04-20" \
    2>/dev/null)

  if [ -z "$RESPONSE" ]; then
    return 1
  fi

  if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    return 1
  fi

  now=$(date +%s)
  echo "$RESPONSE" | jq --argjson ts "$now" '. + {cached_at: $ts}' > "$CACHE_FILE"
  chmod 600 "$CACHE_FILE"
  echo "$RESPONSE"
  return 0
}

# --- メイン処理 ---
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# ホームディレクトリを ~ に短縮
short_cwd=$(echo "$cwd" | sed "s|$HOME|~|")

# モデル名を短縮（例: "Claude Sonnet 4.6" → "Sonnet 4.6"）
short_model=$(echo "$model" | sed 's/^Claude //')

# --- コンテキストウィンドウ プログレスバー ---
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar_len=10
  filled=$(( used_int * bar_len / 100 ))
  empty_bars=$(( bar_len - filled ))

  bar=""
  i=0; while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i+1)); done
  i=0; while [ $i -lt $empty_bars ]; do bar="${bar}░"; i=$((i+1)); done

  ctx_color=$(get_color "$used_int")
  ctx_part=$(printf "${ctx_color}%s %d%%\033[0m" "$bar" "$used_int")
else
  ctx_part="░░░░░░░░░░ --%"
fi

# --- レート制限データ ---
usage_data=$(get_cached_data) || usage_data=$(fetch_usage_data)

if [ -n "$usage_data" ]; then
  five_h_pct=$(echo "$usage_data" | jq '.five_hour.utilization // empty' 2>/dev/null)
  five_h_reset=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  seven_d_pct=$(echo "$usage_data" | jq '.seven_day.utilization // empty' 2>/dev/null)
  seven_d_reset=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

  if [ -n "$five_h_pct" ] && [ -n "$seven_d_pct" ]; then
    five_h_remain=$(format_time_remaining "$five_h_reset")
    seven_d_remain=$(format_time_remaining "$seven_d_reset")

    five_color=$(get_color "$five_h_pct")
    seven_color=$(get_color "$seven_d_pct")

    rate_part=$(printf "⚡${five_color}5h:%d%%→%s\033[0m ${seven_color}7d:%d%%→%s\033[0m" \
      "$five_h_pct" "$five_h_remain" "$seven_d_pct" "$seven_d_remain")
  else
    rate_part="⚡---"
  fi
else
  rate_part="⚡---"
fi

# --- コスト ---
if [ -n "$cost" ]; then
  cost_part=$(printf "\$%.2f" "$cost")
else
  cost_part=""
fi

# --- 出力組み立て ---
# フォーマット: Model  ~/pj ▎ ████░░ 40% ▎ ⚡5h:75%→2.3h 7d:23%→5d ▎ $0.31
if [ -n "$cost_part" ]; then
  printf "%s  %s ▎ %s ▎ %s ▎ %s\n" \
    "$short_model" "$short_cwd" "$ctx_part" "$rate_part" "$cost_part"
else
  printf "%s  %s ▎ %s ▎ %s\n" \
    "$short_model" "$short_cwd" "$ctx_part" "$rate_part"
fi
