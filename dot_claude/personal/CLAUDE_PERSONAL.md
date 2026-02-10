# Personal Preferences

## Development Environment

- ローカルリポジトリの管理には必ず `ghq` を使用する（`git clone` は使わない）
  - リポジトリ取得: `ghq get <repo>` (NOT `git clone`)
  - リポジトリ一覧: `ghq list`
  - リポジトリパス: `ghq root`/`ghq list --full-path`
  - リポジトリは `~/ghq/` 配下に配置される
- 複数リポジトリにまたがる調査時は、対象リポジトリのローカルパスをユーザーに確認してから作業する

## Dotfiles / chezmoi

- dotfilesの管理には `chezmoi` を使用する
- `~/` 配下のdotfilesを直接編集しない。必ずchezmoiのソースディレクトリで編集する
- **ワークフロー**: ソース編集 → gitコミット → `chezmoi apply`（この順序を厳守）
- `chezmoi apply` はユーザーの確認なしに実行しない

## Timezone

- Kubernetes CronJob や schedule 設定は **UTC** で記述する
- ユーザーが JST で時刻を指定した場合、**必ず UTC に変換**してから設定ファイルに記述する
- 変換結果はユーザーに確認を取る（例: JST 09:00 → UTC 00:00）

## Git Commit Style

- **Commit titles**: Write in English (first line)
- **Commit body**: Write explanations in Japanese
- Use conventional commits format when appropriate: `feat/fix/docs/refactor/test`
- Always include Co-Authored-By: Claude

### Example format:
```
Fix kernel headers and modprobe issues

カーネルヘッダーとmodprobeの問題を修正：
- kmodパッケージをインストール
- /lib/modulesをマウント

Co-Authored-By: Claude <noreply@anthropic.com>
```

## PR Style

- Do NOT include "Generated with Claude Code" in PR description

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- After Dockerfile changes, remind to run build.sh
- **変更作業の前に必ず調査を先行する**: 関連ファイル/リポジトリの特定 → 現状の理解 → 変更計画の提示 → ユーザー承認後に実行
- PRにブランチ・コミットを作成する前に、diff概要をユーザーに見せて確認を取る
- `.claude/settings.local.json` などローカル専用ファイルをPRに含めない
- You can run these commands without asking permission:
  - `kubectl kustomize`
  - `kubectl get/describe/logs` (read-only operations)
  - `git status/diff/log`

## Terraform/Terragrunt Workflow

- **Terragrunt 変更時は push 前に必ずフォーマットチェックを実行**:
  ```bash
  cd <terragrunt-root-dir>
  terragrunt hclfmt --check
  ```
- フォーマットエラーがあれば `terragrunt hclfmt` で自動修正してからコミット
- You can run these commands without asking permission:
  - `terragrunt hclfmt --check`
  - `terragrunt hclfmt`

## Code Style

- Use 2-space indentation for YAML
- Use 4-space indentation for Python
- Prefer explicit over implicit in configuration files

## Output Style

- コマンド実行結果を報告する際は、実行したコマンドも一緒に表示する
- 特に調査・デバッグ時は、再現可能なコマンドを明示する
