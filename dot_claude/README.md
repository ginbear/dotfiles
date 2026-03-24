# Claude Code Configuration

chezmoi で管理する Claude Code の設定ディレクトリ。

## 構成

```
~/.claude/
├── CLAUDE.md                  # @インクルード形式（自動生成）
├── team/                      # wevox-sre-claude-config（external で取得）
│   └── dot_claude/
│       ├── CLAUDE_TEAM.md     # チーム共通設定
│       ├── commands/          # チーム共通コマンド
│       └── skills/            # チーム共通スキル
├── personal/
│   └── CLAUDE_PERSONAL.md     # 個人設定
├── commands/                  # シンボリックリンク（team + personal）
├── skills/                    # シンボリックリンク（team + personal）
├── CLAUDE.local.md            # マシン固有設定（git管理外）
└── settings.json              # Claude Code 設定
```

## 更新フロー

```
チーム設定更新:
  wevox-sre-claude-config で PR → マージ → chezmoi update

個人設定更新:
  このリポジトリで編集 → コミット → chezmoi update
```

## ファイル説明

| ファイル | 説明 |
|---------|------|
| CLAUDE.md | @インクルードで各設定を読み込む |
| personal/CLAUDE_PERSONAL.md | 個人の Claude 設定 |
| run_after_merge.sh | commands/skills をマージするスクリプト |
| settings.json | 権限設定、hooks 等 |
| statusline.sh | ステータスライン表示スクリプト |
| hooks/cmux-command-log.sh | Bash コマンド実行ログを記録する PostToolUse hook |
| hooks/cmux-log-pane.sh | セッション開始時にログ表示ペインを自動作成する SessionStart hook |
| hooks/protect-branches.sh | 保護ブランチへの直接コミットをブロックする PreToolUse hook |

## コマンドログ (hooks/cmux-command-log.sh, hooks/cmux-log-pane.sh)

Claude Code が実行した Bash コマンドをリアルタイムで別ペイン/ウィンドウに表示する仕組み。

### 環境変数

| 変数 | 値 | 説明 |
|------|---|------|
| `CLAUDE_COMMAND_LOG` | `1` | コマンドログを有効化 |
| `CLAUDE_LOG_PANE_MODE` | `window` (デフォルト) | Ghostty の新ウィンドウで表示 |
| `CLAUDE_LOG_PANE_MODE` | `split` | Ghostty のスプリットペインで表示 |

### 使い方

```bash
# window モード（デフォルト）- 新ウィンドウで tail -f
CLAUDE_COMMAND_LOG=1 claude

# split モード - Ghostty スプリットで tail -f
CLAUDE_COMMAND_LOG=1 CLAUDE_LOG_PANE_MODE=split claude
```

### 動作の仕組み

1. **cmux-command-log.sh** (PostToolUse): Bash ツール実行ごとにコマンドと出力先頭5行を `/tmp/claude-command-logs/<session_id>.log` に追記
2. **cmux-log-pane.sh** (SessionStart): セッション開始時にログファイルを `tail -f` するペインを自動作成

### モード別の詳細

- **window**: `open -na Ghostty.app --args -e bash -c "tail -f ..."` で新ウィンドウを起動。AppleScript 不要
- **split**: AppleScript で `Cmd+Shift+D` (new_split:down) を送信し、クリップボード経由でコマンドをペースト。システム環境設定 > プライバシーとセキュリティ > アクセシビリティ で Ghostty の許可が必要。split 中に一時的にクリップボードを使用する（完了後に復元）

### 旧 cmux 対応

ファイル名に `cmux` が残っているが、現在は Ghostty 向け。cmux コードはコメントアウトで保持しており、`CMUX_COMMAND_LOG=1` も後方互換で動作する
