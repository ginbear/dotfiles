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
- chezmoi ソースディレクトリは ghq 管理のリポジトリへのシンボリックリンク:
  - `~/.local/share/chezmoi` → `~/ghq/github.com/ginbear/dotfiles`
  - どちらのパスでもアクセス可能だが、ghq 側のパスを使う
- `~/` 配下のdotfilesを直接編集しない。必ずchezmoiのソースディレクトリで編集する
- **よくある間違い**: `~/.claude/` 配下を直接編集してはいけない。`~/ghq/github.com/ginbear/dotfiles/dot_claude/` を編集する
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
- PR作成前に `git diff` の全体を確認し、意図した変更のみが含まれていることを検証する
- 複数環境（dev/stg/prd）にまたがる変更では、各環境の現在値を git 上で確認してから diff を作成する（実態と乖離していないか検証）
- 以下のファイルは絶対に PR に含めない: `.claude/settings.local.json`, `.env`, `*.tfvars`（機密情報）

## 回答の正確性

- ツールの機能・設定項目について確信がない場合は「未確認」と明示し、公式ドキュメントや `--help` で確認してから回答する
- 「できない」「存在しない」と断言する前に、実際にコマンドやドキュメントで検証する
- AWS/Datadog 等の料金・インスタンスタイプ・設定上限値を提示する際は、Web検索または公式ドキュメントで検証してから回答する。未検証の場合は「未検証」と明記する

## Investigation Workflow

K8sリソースやインフラの調査時は以下の順序で実施する:
1. `kubectl get/describe` で現在の状態を確認
2. `kubectl logs` でエラー詳細を確認
3. **ローカルマニフェスト/Terraformを Grep/Read で検索**し、設定の意図を把握
4. 必要に応じて Datadog でメトリクス/ログを確認
5. 調査結果をまとめてからアクション提案（勝手に修正しない）

### リソース変更の安全確認
- 既存リソースの置換・修正を提案する前に、現在の実装を必ず読んで機能等価性を確認する
- image / templateRef / kustomize overlay の差し替えは「同じ動作をする」ことを検証してから提案する
- 確認せずに「これで置き換えられます」と断言しない

### リソース状態の報告ルール
- kubectl の出力を部分的に見て「正常」と断言しない。STATUS/READY カラムを必ず確認する
- 「動いている」と報告する前に、Pod の STATUS が Running かつ READY が期待値であることを確認する
- 不確かな場合は「未確認」と明示し、確認コマンドを提示する

### セキュリティ調査の注意事項
- ユーザーが指定した CVE 番号は正確にそのまま使う。類似の CVE に勝手に置き換えない
- CVE の詳細を調べる際は、公式ソース（NVD, GitHub Advisory）を参照して正確性を検証する

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- After Dockerfile changes, remind to run build.sh
- **変更作業の前に必ず調査を先行する**: 関連ファイル/リポジトリの特定 → 現状の理解 → 変更計画の提示 → ユーザー承認後に実行
- **複雑な変更の提案前に前提を明示する**: 解決策を提案する前に (1) 対象のリソース/ワークロード種別, (2) リポジトリ内の既存パターン, (3) 自分の前提条件 を列挙し、ユーザーに確認を取る。前提が間違っていると解決策全体が手戻りになる
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
- `terraform plan`/`terragrunt plan` の結果や STDOUT の raw output を報告する際は、要約・整形せずそのまま貼る。markdown テーブル化やサマリ化はユーザーが明示的に要求した場合のみ行う
