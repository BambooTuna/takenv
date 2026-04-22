#!/bin/sh
CACHE_FILE="${HOME}/.claude/statusline-cache.json"
CACHE_TTL=60

# ISO8601 → 残り時間の人間が読みやすい形式（例: 2.3h, 5d）
format_time_remaining() {
  reset_at="$1"
  now=$(date -u +%s)

  # サブ秒・タイムゾーンオフセットを除去して "2006-01-02T15:04:05Z" 形式に正規化
  reset_normalized=$(echo "$reset_at" | sed -e 's/\.[0-9]*//' -e 's/[+-][0-9][0-9]:[0-9][0-9]$/Z/')
  OS=$(uname -s)
  if [ "$OS" = "Darwin" ]; then
    target=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$reset_normalized" +%s 2>/dev/null)
  else
    target=$(date -u -d "$reset_normalized" +%s 2>/dev/null)
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
  if [ "$(uname -s)" = "Darwin" ]; then
    TOKEN=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
  else
    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  fi
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
  # umask 077 でパーミッション600保証（chmod 600 のレースコンディション回避）
  (umask 077; echo "$RESPONSE" | jq --argjson ts "$now" '. + {cached_at: $ts}' > "$CACHE_FILE")
  echo "$RESPONSE"
  return 0
}

# --- メイン処理 ---
input=$(cat)

# 1回のjq呼び出しでstdinの全フィールドをTAB区切りで取得
_parsed=$(echo "$input" | jq -r '
  [
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    ((.context_window.used_percentage // "") | tostring),
    ((.cost.total_cost_usd // "") | tostring),
    ((.rate_limits.five_hour.used_percentage // "") | tostring),
    ((.rate_limits.seven_day.used_percentage // "") | tostring)
  ] | join("\t")
')
_old_IFS="$IFS"
IFS="$(printf '\t')"
read -r cwd model used cost stdin_five_h stdin_seven_d << HDOC
$_parsed
HDOC
IFS="$_old_IFS"
unset _parsed _old_IFS

# ホームディレクトリを ~ に短縮（メタ文字安全）
short_cwd="${cwd#"$HOME"}"
[ "$short_cwd" != "$cwd" ] && short_cwd="~$short_cwd"

# モデル名を短縮（例: "Claude Sonnet 4.6" → "Sonnet 4.6"）
short_model=$(echo "$model" | sed 's/^Claude //')

# --- コンテキストウィンドウ プログレスバー ---
if [ -n "$used" ] && [ "$used" != "null" ]; then
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
# stdinから使用率が取れるか判定
_have_stdin_rate=""
if [ -n "$stdin_five_h" ] && [ "$stdin_five_h" != "null" ] && \
   [ -n "$stdin_seven_d" ] && [ "$stdin_seven_d" != "null" ]; then
  _have_stdin_rate=1
  five_h_pct="$stdin_five_h"
  seven_d_pct="$stdin_seven_d"
fi

# stdinから取れない場合はAPIにフォールバック
if [ -z "$_have_stdin_rate" ]; then
  usage_data=$(get_cached_data) || usage_data=$(fetch_usage_data)
  if [ -n "$usage_data" ]; then
    _rate=$(echo "$usage_data" | jq -r '
      [
        ((.five_hour.utilization // "") | tostring),
        (.five_hour.resets_at // ""),
        ((.seven_day.utilization // "") | tostring),
        (.seven_day.resets_at // "")
      ] | join("\t")
    ')
    _old_IFS="$IFS"
    IFS="$(printf '\t')"
    read -r five_h_pct five_h_reset seven_d_pct seven_d_reset << HDOC
$_rate
HDOC
    IFS="$_old_IFS"
    unset _rate _old_IFS
  fi
else
  # stdinで使用率は取れたが、resets_atはAPIから補完
  usage_data=$(get_cached_data) || usage_data=$(fetch_usage_data)
  if [ -n "$usage_data" ]; then
    _resets=$(echo "$usage_data" | jq -r '
      [
        (.five_hour.resets_at // ""),
        (.seven_day.resets_at // "")
      ] | join("\t")
    ')
    _old_IFS="$IFS"
    IFS="$(printf '\t')"
    read -r five_h_reset seven_d_reset << HDOC
$_resets
HDOC
    IFS="$_old_IFS"
    unset _resets _old_IFS
  fi
fi
unset _have_stdin_rate

if [ -n "$five_h_pct" ] && [ "$five_h_pct" != "null" ] && \
   [ -n "$seven_d_pct" ] && [ "$seven_d_pct" != "null" ]; then
  # 小数値を整数に変換してから色・表示に使用
  five_h_int=$(printf "%.0f" "$five_h_pct")
  seven_d_int=$(printf "%.0f" "$seven_d_pct")
  five_color=$(get_color "$five_h_int")
  seven_color=$(get_color "$seven_d_int")

  # 残り時間が取れている場合は表示、なければパーセントのみ
  if [ -n "$five_h_reset" ] && [ "$five_h_reset" != "null" ] && [ "$five_h_reset" != "" ]; then
    five_h_remain=$(format_time_remaining "$five_h_reset")
    five_h_display=$(printf "%d%%→%s" "$five_h_int" "$five_h_remain")
  else
    five_h_display=$(printf "%d%%" "$five_h_int")
  fi

  if [ -n "$seven_d_reset" ] && [ "$seven_d_reset" != "null" ] && [ "$seven_d_reset" != "" ]; then
    seven_d_remain=$(format_time_remaining "$seven_d_reset")
    seven_d_display=$(printf "%d%%→%s" "$seven_d_int" "$seven_d_remain")
  else
    seven_d_display=$(printf "%d%%" "$seven_d_int")
  fi

  rate_part=$(printf "⚡${five_color}5h:%s\033[0m ${seven_color}7d:%s\033[0m" \
    "$five_h_display" "$seven_d_display")
else
  rate_part="⚡---"
fi

# --- コスト ---
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
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
