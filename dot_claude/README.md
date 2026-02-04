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
