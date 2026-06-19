#!/bin/bash
# UserPromptSubmit Hook: 全プロンプトを ~/.claude/logs/prompts.jsonl に追記する。
# フィルタや集計は /prompt-digest 側で行う。

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$PROMPT" ] || [ ${#PROMPT} -lt 5 ]; then
  exit 0
fi

LOG_DIR="$HOME/.claude/logs"
umask 077
mkdir -p "$LOG_DIR"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -nc \
  --arg ts "$TS" \
  --arg session "$SESSION_ID" \
  --arg cwd "$CWD" \
  --arg prompt "$PROMPT" \
  '{ts:$ts, session:$session, cwd:$cwd, prompt:$prompt}' \
  >> "$LOG_DIR/prompts.jsonl"

exit 0
