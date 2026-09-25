# Personal Preferences

## Development Environment

- ローカルリポジトリは `ghq` で `~/ghq/` 配下に管理している
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

## Git Worktree

- 同じリポジトリで並行してPRを進める場合、branchごとに `git worktree add` で作業ディレクトリを分ける
- 命名規則: `<repo>-worktrees/<branch-name>`（ghq root 配下に置く。`ghq list` に出るのは意図通り — branchへすぐ切り替えられる利点を優先する）
- dotfiles リポジトリは worktree 対象外にする（`~/.local/share/chezmoi` は ghq 上の main checkout を指すシンボリックリンクのため、worktree で編集しても `chezmoi apply` に反映されない）
- PRがマージされたら、対応する worktree を `git worktree remove` で削除する。session が落ちて消し忘れることはあり得るので、気づいた時点で棚卸しして削除する

## Timezone

- Kubernetes CronJob や schedule 設定は **UTC** で記述する
- ユーザーが JST で時刻を指定した場合、**必ず UTC に変換**してから設定ファイルに記述する
- 変換結果はユーザーに確認を取る（例: JST 09:00 → UTC 00:00）

## Git Commit Style

- **Commit titles**: Write in English (first line)
- **Commit body**: Write explanations in Japanese
- Use conventional commits format when appropriate: `feat/fix/docs/refactor/test`

## PR Style

- PR作成前に `git diff` の全体を確認し、意図した変更のみが含まれていることを検証する
- 複数環境（dev/stg/prd）にまたがる変更では、各環境の現在値を git 上で確認してから diff を作成する（実態と乖離していないか検証）
- ブランチを作る前に `git fetch origin` する。起点は fetch 直後の `origin/<base>` を明示的に指定する（古いローカル ref を起点にすると後で conflict になる）

## Investigation Workflow

### 結論の述べ方
- 根本原因は根拠（Datadog/kubectl/docs）で検証してから断定する。弱いシグナル1つで環境・対象を早期に絞り込まない
- 仮説には「何が観測されれば反証されるか」を併記し、確信度をキャリブレーションして述べる
- 検証していないことは「未確認」と明示し、確認コマンドか公式ソース（docs / NVD / GitHub Advisory 等）を併記する

### リソース変更の安全確認
- 既存リソースの置換・修正を提案する前に、現在の実装を必ず読んで機能等価性を確認する
- image / templateRef / kustomize overlay の差し替えは「同じ動作をする」ことを検証してから提案する
- 確認せずに「これで置き換えられます」と断言しない

### リソース状態の報告ルール
- kubectl の出力を部分的に見て「正常」と断言しない。STATUS/READY カラムを必ず確認する
- 「動いている」と報告する前に、Pod の STATUS が Running かつ READY が期待値であることを確認する

### 調査結果の記録
- 調査結果は基本的に **GitHub Issue に記録する前提** で整理する（実際に書き込むかはユーザーが判断する）
- 10行以上の出力は `<details>` タグで折りたたむ
- 内容は**事実と推測を明確に書き分ける**

### セキュリティ調査の注意事項
- ユーザーが指定した CVE 番号は正確にそのまま使う。類似の CVE に勝手に置き換えない

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- **変更前に計画の承認を取る**: 対象リソース・リポジトリ内の既存パターン・自分の前提を示した変更計画を出し、承認後に実行する
- **正規の修正を優先**: 問題の調査時、ワークアラウンドを先に提案しない。まず正規・推奨の修正方法を特定し、それが不可能な場合のみワークアラウンドを提案する

## Production Safety

- prd 環境への exec / write / 破壊的コマンド（`kubectl exec`, `delete`, `apply` 等）は**実行前に必ずユーザーへ確認**する。先に dev/stg または read-only の代替を提示する

## Terraform/Terragrunt Workflow

- **plan/apply の実行は `/terraform-plan`, `/terraform-apply` skill を使用する**（ログ保存・検証・記録投稿を一貫して行うため）

## コマンド実行ポリシー

- **参照系コマンドは Claude Code が実行**して内容を確認する（`kubectl get/describe`, `aws ... describe`, `git log/diff` 等）
- **更新系コマンドは原則ユーザーが実行**する。**コピペしやすい形**でコマンドを提示する（`kubectl apply/delete`, `git push` 等）。内容によっては Claude に対応を依頼してもよい（例: terraform/terragrunt apply は `/terraform-apply` skill 経由）
- 破壊的・インフラ変更は、レビューして1つずつ実行できるよう**リソースごとの個別コマンド**で提示する。依頼がない限りスクリプトにまとめない
- コマンドで何かを確認したら、ユーザーが再確認できるよう**実行したコマンドをコピペしやすい形で必ず併記**する

## Code Style

- **コメントの原則**（[t_wadaの整理](https://x.com/t_wada/status/904916106153828352)）: コードには How、テストコードには What、コミットログには Why、コードコメントには Why not
  - コメントアウトはコードを読めばわかることを書かない。過去の経緯も書かない（背景は PR description に書く）。コードを読んでもわからないことに限定して簡潔に記載する
- **コメントは最大1行**。収まらない分はコミットメッセージか PR 説明に書く
- 既存コメントを消せるなら、追記より削除を先に検討する
- 使い捨ての整形・パース（JSON/YAML の抽出等）は言語を問わずワンライナーでよい

## Output Style

- **コマンド出力は実際に得たものをそのまま貼る**。要約・整形・別環境の出力の流用をしない。得られなければ再実行する
- ターミナルへの応答で PR / issue に言及するときはクリックできるリンクにする。複数リポジトリを並行して扱うため、番号だけではどのリポジトリか判別できない
  - 形式: `[org/repo#1234](https://github.com/org/repo/issues/1234)`
  - 同一リポジトリの話が続く文脈では表示名を `#1234` に短縮してよいが、URL は必ず付ける
  - 対象は会話の応答。issue コメント・PR 説明など GitHub に書くものは `org/repo#1234` 形式で十分（GitHub 側が解決する）
