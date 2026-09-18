---
name: terraform-apply-by-human
description: Terraform/Terragruntのapplyを人間が実行する場合に、planの実行・レビューと結果の検証・記録をAIが担当する
user_invocable: true
---

# Terraform Apply（人間が実行）

plan の実行とレビュー、apply 結果の検証と記録を AI が担当し、**apply の実行だけを人間に渡す**。

`terraform-apply` skill との使い分け:

| | apply の実行者 | 確認ゲート |
|---|---|---|
| `terraform-apply` | AI | `-out` で保存した plan の sha256 照合 + チャット上の明示確認 |
| **本 skill** | 人間 | terraform/tofu 自身の `yes` プロンプト |

`-out` + checksum 方式は AI が対話ターミナルを持たないことの代替なので、人間が実行するなら不要。plan ファイルを作らず、対話 apply のプロンプトを確認ゲートにする。

## 前提条件

- 既に `/terraform-plan` で target なしの plan を確認済みで、ユーザーが適用方針（全適用 or `-target`）を確認済みであること

## Step 1: 事前確認

ユーザーに以下を確認する（引数で指定済みの場合はスキップ）:
- 実行ディレクトリ（絶対パス）
- terraform か terragrunt か
- workspace（該当する場合）
- 記録の投稿先（PR コメント / Issue コメント / なし）
- `-target` リソース一覧（plan で `-target` 適用が選択された場合）

### バージョンマネージャの prefix が必要か判定する

人間が使う対話シェルでバージョンマネージャが有効化されていれば prefix は不要。有効化されていなければ Step 3 のコマンドに prefix を付ける。

```bash
grep -rn "mise activate" ~/.zshrc ~/.zshenv ~/.zprofile 2>/dev/null
```

### 複数ユニットを適用する場合の順序

terragrunt で `dependency` を持つユニットは、依存先が**実際に apply されるまで plan できない**ことがある。依存先の出力が mock で埋められる範囲を確認する。

```bash
grep -A5 'dependency "' <ユニットの terragrunt.hcl>
```

`mock_outputs_allowed_terraform_commands` に `apply` が含まれない場合、`plan → apply → plan → apply` と**交互に進める**。全ユニットの plan をまとめて先に済ませることはできない。

## Step 2: Plan の実行とレビュー（AI）

```bash
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> plan [-target=<resource> ...] 2>&1
```

- workspace がある場合は `workspace select` を先に実行する（各 Bash 呼び出しはシェルが独立するため）
- 期待した差分のみであることを確認する。想定外の差分があればここで止めてユーザーに報告する
- plan ファイルは保存しない（人間が apply 時に自分の目で plan を見るため）

## Step 3: Apply コマンドの提示（人間が実行）

ユーザーに以下を提示する:
- **env**: workspace 名を人間が読める形に変換して明記する（例: dev→development, prd→production。workspace が無い場合は対象ディレクトリ名）
- **`-target` の有無**: 指定した場合は対象リソースのアドレス一覧も併記する
- **結果サマリー**: `Plan: N to add, N to change, N to destroy` の行
- **変更内容サマリー**: リソースごとの diff を簡潔に

その上で、apply コマンドを提示する。**シェル変数・checksum 照合・`tee` を含めない。** 人間は新しいターミナルに貼り付けるため変数は空に展開され、複合コマンドは部分コピペを招く。

```bash
cd <実行ディレクトリの絶対パス>
<terraform or terragrunt> apply [-target=<resource> ...]
```

- workspace がある場合は `<terraform or terragrunt> workspace select <workspace>` を間に挟む
- Step 1 でバージョンマネージャが有効化されていなかった場合のみ、`apply` の行に prefix を付ける
- `-auto-approve` は付けない。プロンプトで plan を確認して `yes` を入力するのが確認ゲート

「プロンプトで plan が出るので、`N to add, N to change, N to destroy` を確認して `yes`」と伝え、**実行後の出力を貼り戻すよう依頼する**。

## Step 4: 貼り戻された出力の保存（記録の唯一のソース）

AI が apply を実行していないため `tee` によるログが存在せず、**貼り戻された出力が記録の唯一のソースになる**。レビューより先に、受け取った出力を**そのまま**ファイルに保存する。

```bash
LOG_DIR="$HOME/terraform-logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"
cat > "${LOG_DIR}/apply_<連番>_<ユニット名>_<env>.log" <<'EOF'
<貼り戻された出力をそのまま>
EOF
```

Step 7 の記録はこのファイルを読んで作る。チャットのスクロールバックから再構成してはならない。

## Step 5: Apply 結果の検証（AI）

- `Apply complete! Resources: N added, N changed, N destroyed.` が Step 2 の plan と一致するか確認する
- **変更が期待されるのに 0 changes だった場合**: 次のステップに進まず、ユーザーに報告する
- エラーが出ている場合: エラー内容をそのまま報告し、ユーザーの指示を仰ぐ
- 複数ユニットの交互進行中であれば、ここで次のユニットの Step 2 に戻る

## Step 6: Post-apply Plan（AI）

参照系なので AI が実行する。同じディレクトリ・同じ workspace で plan を実行し、差分が出ないことを確認する。

```bash
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> plan 2>&1
```

- `-target` なしで apply した場合: `No changes` が確認できれば OK
- `-target` で apply した場合: target 対象のリソースに差分が残っていないことを確認する（target 外に差分が残るのは想定通り）
- 想定外の差分が残っている場合: ユーザーに報告し、次のステップに進まない

`No changes` はリソースが state と一致したことしか示さない。その変更が直すはずだった観測対象（CI チェック、メトリクス、エラーの消滅など）があれば、それも確認してから完了とする。

## Step 7: 記録の投稿

投稿先が指定されている場合、以下のフォーマットで投稿する。
**raw output は Step 4 で保存したログファイルから読み取る。**

~~~markdown
## <terraform or terragrunt> apply result

### <適用したリソースの概要>

`<実行コマンド>`

```
<結果サマリー: N added, N changed, N destroyed>
```

<details><summary>raw output</summary>

```
<ログファイルの内容をそのまま貼り付け>
```

</details>
~~~

PR コメントの場合:
```bash
gh pr comment <PR番号> --repo <owner>/<repo> -F <本文ファイル>
```

Issue コメントの場合:
```bash
gh issue comment <Issue番号> --repo <owner>/<repo> -F <本文ファイル>
```

本文はファイルに書き出して `-F` で渡す（`-f body=@file` は文字列そのまま扱われる）。

## Step 8: 完了報告

- Apply 結果のサマリー
- Post-apply plan の結果
- Step 4 で保存したログファイルのパス
- 記録の投稿先（投稿した場合）

## 注意事項

- **AI は apply を実行しない。** 提示したコマンドを自分で実行しない
- 貼り戻された出力は要約・整形せずそのまま保存する。別環境の出力を書き換えて使わない
- 複数環境を順に apply する場合、各環境ごとに Step 2〜7 を完了してから次の環境に進む
