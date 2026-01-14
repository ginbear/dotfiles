#!/bin/bash
# Claude Code 会話をObsidianに自動保存するスクリプト
# 参考: https://zenn.dev/pepabo/articles/ffb79b5279f6ee

set -euo pipefail

OBSIDIAN_DIR="${HOME}/obsidian-local/Claude-Code"
CLAUDE_PROJECTS_DIR="${HOME}/.claude/projects"
STATE_FILE="${HOME}/.claude/watch-state.json"
TODAY=$(TZ=Asia/Tokyo /bin/date +%Y-%m-%d)

# 状態ファイルの初期化
if [[ ! -f "$STATE_FILE" ]]; then
  echo '{}' > "$STATE_FILE"
fi

# プロジェクト名を抽出（パスから）
extract_project_name() {
  local dir_name="$1"
  # -Users-ryoshimizu-ghq-github-com-Atrae-wevox-infrastructure -> wevox-infrastructure
  echo "$dir_name" | rev | cut -d'-' -f1-2 | rev | sed 's/^-//'
}

# リポジトリパスを抽出（ディレクトリ名から）
extract_repository_path() {
  local dir_name="$1"
  # -Users-ryoshimizu-ghq-github-com-ginbear-zenn -> /Users/ryoshimizu/ghq/github.com/ginbear/zenn
  echo "$dir_name" | sed 's/^-/\//' | sed 's/-com-/.com\//g' | sed 's/-/\//g'
}

# ノイズを除去
remove_noise() {
  local text="$1"
  # system-reminder, local-command, command-name, task-notification タグを除去
  echo "$text" | sed -E 's/<(system-reminder|local-command|command-name|task-notification)>[^<]*<\/[^>]+>//g'
}

# メッセージ内容を抽出（テキストのみ）
extract_content() {
  local json="$1"
  local type=$(echo "$json" | jq -r '.type // empty')
  local content=""

  if [[ "$type" == "user" ]]; then
    # contentが文字列の場合はそのまま、配列の場合はtextタイプのみ抽出
    content=$(echo "$json" | jq -r '
      .message.content |
      if type == "string" then .
      elif type == "array" then
        map(select(.type == "text") | .text) | join("\n")
      else empty
      end
    ')
  elif [[ "$type" == "assistant" ]]; then
    # assistantのcontentは配列、textタイプのみ抽出
    content=$(echo "$json" | jq -r '
      .message.content // [] |
      map(select(.type == "text") | .text) |
      join("\n")
    ')
    # "No response requested" で始まる場合は空にする
    if [[ "$content" == "No response requested"* ]]; then
      content=""
    fi
  fi

  # ノイズ除去して返す
  remove_noise "$content"
}

# メインの処理
process_sessions() {
  local state=$(cat "$STATE_FILE")

  # 各プロジェクトディレクトリを処理
  for project_dir in "$CLAUDE_PROJECTS_DIR"/-*; do
    [[ -d "$project_dir" ]] || continue

    local project_name=$(extract_project_name "$(basename "$project_dir")")

    # 各セッションファイルを処理（agent-* は除外）
    for session_file in "$project_dir"/*.jsonl; do
      [[ -f "$session_file" ]] || continue
      [[ "$(basename "$session_file")" == agent-* ]] && continue

      local session_id=$(basename "$session_file" .jsonl)
      local state_key="${project_name}/${session_id}"
      local processed_lines=$(echo "$state" | jq -r --arg k "$state_key" '.[$k] // 0')
      local total_lines=$(wc -l < "$session_file" | tr -d ' ')

      # 新しい行がなければスキップ
      [[ "$processed_lines" -ge "$total_lines" ]] && continue

      # 今日の会話を抽出してMarkdownに追記（セッションごとにファイル分割）
      local short_session_id=$(echo "$session_id" | cut -c1-8)
      local output_file="${OBSIDIAN_DIR}/${TODAY}-${project_name}-${short_session_id}.md"
      local temp_file=$(mktemp)

      # 新しい行だけを処理（一時ファイルに書き込み）
      tail -n +"$((processed_lines + 1))" "$session_file" | while IFS= read -r line; do
        local msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null || true)
        local timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null || true)

        # user/assistant メッセージのみ処理
        [[ "$msg_type" != "user" && "$msg_type" != "assistant" ]] && continue

        # 今日の日付のみ処理（タイムスタンプはUTCなのでJSTに変換）
        [[ -n "$timestamp" ]] || continue
        local ts_clean="${timestamp%.???Z}"
        local epoch=$(/bin/date -j -u -f "%Y-%m-%dT%H:%M:%S" "$ts_clean" "+%s" 2>/dev/null || echo "0")
        local msg_date=$(TZ=Asia/Tokyo /bin/date -r "$epoch" "+%Y-%m-%d" 2>/dev/null || echo "$timestamp" | cut -d'T' -f1)
        [[ "$msg_date" != "$TODAY" ]] && continue

        local content=$(extract_content "$line")
        [[ -z "$content" || "$content" == "null" ]] && continue

        local time=$(TZ=Asia/Tokyo /bin/date -r "$epoch" "+%H:%M:%S")
        local role_label="User"
        [[ "$msg_type" == "assistant" ]] && role_label="Claude"

        {
          echo "## ${role_label} (${time})"
          echo ""
          echo "$content"
          echo ""
          echo "---"
          echo ""
        } >> "$temp_file"
      done

      # 一時ファイルに内容があれば本ファイルに追記
      if [[ -s "$temp_file" ]]; then
        # ファイルが存在しなければフロントマターとヘッダーを追加
        if [[ ! -f "$output_file" ]]; then
          local repo_path=$(extract_repository_path "$(basename "$project_dir")")
          local created_time=$(TZ=Asia/Tokyo date +%Y-%m-%dT%H:%M:%S%z)
          cat > "$output_file" << EOF
---
created: ${created_time}
project: ${project_name}
repository: ${repo_path}
session_id: ${session_id}
tags:
  - claude-code
---

# Claude Code - ${project_name} (${TODAY})

EOF
        fi
        cat "$temp_file" >> "$output_file"
      fi
      rm -f "$temp_file"

      # 状態を更新
      state=$(echo "$state" | jq --arg k "$state_key" --argjson v "$total_lines" '.[$k] = $v')
    done
  done

  # 状態を保存
  echo "$state" > "$STATE_FILE"
}

# メイン実行
while true; do
  process_sessions
  sleep 5
done
