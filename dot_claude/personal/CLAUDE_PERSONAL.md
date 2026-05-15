# Personal Preferences

## Development Environment

- ローカルリポジトリの管理には `ghq` を使用する（`git clone` は PreToolUse hook でブロックされる）
  - リポジトリ取得: `ghq get <repo>`
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
- `~/.claude/` 配下の直接編集は permissions deny でブロックされる。`~/ghq/github.com/ginbear/dotfiles/dot_claude/` を編集すること
  - テスト時は `Bash(cp ...)` で一時デプロイ可能（deny は Edit/Write ツールのみ対象）
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
- 機密ファイル（`.env`, `*.tfvars`, `settings.local.json`）の `git add` は PreToolUse hook で機械的にブロックされる

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

### 調査結果の記録
- 調査結果は基本的に **GitHub Issue に記録する前提** で整理する（実際に書き込むかはユーザーが判断する）
- 10行以上の出力は `<details>` タグで折りたたむ
- 内容は**事実と推測を明確に書き分ける**

### セキュリティ調査の注意事項
- ユーザーが指定した CVE 番号は正確にそのまま使う。類似の CVE に勝手に置き換えない
- CVE の詳細を調べる際は、公式ソース（NVD, GitHub Advisory）を参照して正確性を検証する

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- After Dockerfile changes, remind to run build.sh
- **変更作業の前に必ず調査を先行する**: 関連ファイル/リポジトリの特定 → 現状の理解 → 変更計画の提示 → ユーザー承認後に実行
- **複雑な変更の提案前に前提を明示する**: 解決策を提案する前に (1) 対象のリソース/ワークロード種別, (2) リポジトリ内の既存パターン, (3) 自分の前提条件 を列挙し、ユーザーに確認を取る。前提が間違っていると解決策全体が手戻りになる
- PRにブランチ・コミットを作成する前に、diff概要をユーザーに見せて確認を取る

## Terraform/Terragrunt Workflow

- **Terragrunt 変更時は push 前に必ずフォーマットチェックを実行**:
  ```bash
  cd <terragrunt-root-dir>
  terragrunt hclfmt --check
  ```
- フォーマットエラーがあれば `terragrunt hclfmt` で自動修正してからコミット
- **期待と異なる結果での停止**: terraform/terragrunt の plan/apply が 0 changes を返したが変更が期待される場合、次の環境やコメント作成に進まずユーザーに報告して指示を仰ぐ。「既に適用済み」と自己判断しない
- **plan/apply の実行は `/terraform-plan`, `/terraform-apply` skill を使用する**（ログ保存・検証・記録投稿を一貫して行うため）

## Bash コマンドのルール

- 他リポジトリや別ディレクトリを参照する際は、原則 `cd` せず**絶対パスを引数に渡す**
  - これにより `settings.json` の許可パターン（`Bash(grep *)`, `Bash(ls *)` 等）が正しくマッチし、不要な確認プロンプトを回避できる
  - 例: `grep -r 'pattern' /absolute/path/to/repo/` (NOT `cd /path && grep -r 'pattern' .`)
- `cd` が必要なケース（ツールが cwd 依存、相対パス出力が必要等）ではやむを得ず使ってよいが、理由がない限り絶対パスを優先する
- **並列実行時の cd 明示**: 複数の Bash コマンドを並列実行する際、全てのコマンドに `cd <absolute-path> &&` を含める。片方だけ cd して片方は省略するパターンを禁止

## Code Style

- Use 2-space indentation for YAML
- Use 4-space indentation for Python
- Prefer explicit over implicit in configuration files
- スクリプトを書く際は **Ruby を優先** する（want, not must）
  - Python の方が適切な場合（ライブラリの充実度、既存コードとの整合性、コンテキストが少ない等）は Python を使ってよい

## Output Style

- コマンド実行結果を報告する際は、実行したコマンドも一緒に表示する（再現可能な形で）
- コマンド出力や raw output は要約・整形せずそのまま貼る。整形はユーザーが明示的に要求した場合のみ
- **コマンド出力の捏造・書き換え禁止**: 別環境・別コマンドの出力をリネーム・編集して「この環境の結果」として報告しない。出力が得られなかった場合はコマンドを再実行する。「似ているから書き換えれば正しいはず」は禁止
