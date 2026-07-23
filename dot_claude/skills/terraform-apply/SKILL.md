---
name: terraform-apply
description: Terraform/Terragruntのapplyを、-outで保存したplanをレビューしてから適用する方式で安全に実行し、検証・記録まで一貫して行う
user_invocable: true
---

# Terraform Apply（安全実行）

Terraform または Terragrunt の apply を、**保存済み plan ファイルをレビューしてから適用する方式**で実行し、出力保存 → 差分検証 → 記録投稿まで一貫して行う。

## 前提条件

- 既に `/terraform-plan` で target なしの plan を確認済みで、ユーザーが適用方針（全適用 or `-target`）を確認済みであること
- plan 未実施の場合は `/terraform-plan` を先に実行するよう案内する

## なぜ `-out` 方式か

`terraform apply` を対話プロンプトなしで実行する方法は主に2つある。

1. `-auto-approve` — plan の確認プロンプトを丸ごとスキップして即適用する。ユーザーが実際の diff を見る前に適用が走ってしまうリスクがある
2. **`-out=FILE` で plan を保存 → 内容をレビュー → `apply FILE` で保存済み plan をそのまま適用**（本 skill の方式）。保存後にレビュー・チャット上での明示確認を挟めるため、対話ターミナルを持たない実行環境でも実質的な人間の確認チェックポイントを作れる

`apply <planfile>` は保存済み plan をそのまま適用するため対話プロンプト自体が発生しない（`-auto-approve` は不要）。かつ、apply 時に **state が保存後に変わっていた場合は自動的にエラーになり拒否される**（下記「安全性の根拠」参照）。**prd 環境や慎重な適用が必要な場合は、デフォルトでこちらを使う。**

### 安全性の根拠（terraform 本体の挙動）

hashicorp/terraform (`internal/backend/local/backend_local.go`) の実装で確認済み:

- 保存済み plan ファイルには作成時点の state の `lineage`（state 系譜ID）と `serial`（更新連番）が埋め込まれる
- apply 時、現在の実際の state とこれを比較し、**serial 不一致 → `Saved plan is stale` エラーで拒否**、**lineage 不一致 → `Saved plan does not match the given state` エラーで拒否**。どちらの場合も古い plan の強制適用はされない
- ただし `apply <planfile>` は**再 refresh しない**。plan 保存後に AWS 側の実リソースだけが変わった（terraform state には反映されていない）ケースはこの仕組みでは検出されない。対象リソースが `resolve_conflicts_on_update = "OVERWRITE"` など desired 値に収束する更新方式であれば実害は限定的だが、そうでない場合は影響範囲に留意する

## Step 1: 事前確認

ユーザーに以下を確認する（引数で指定済みの場合はスキップ）:
- 実行ディレクトリ（絶対パス）
- terraform か terragrunt か
- workspace（該当する場合）
- 記録の投稿先（PR コメント / Issue コメント / なし）
- `-target` リソース一覧（plan で `-target` 適用が選択された場合）

`-auto-approve` の使用有無は確認不要（本 skill では使用しない）。

## Step 2: Plan をファイルに保存

```bash
LOG_DIR="$HOME/terraform-logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%H-%M-%S)
DIR_NAME=$(basename <実行ディレクトリ>)
WORKSPACE="<workspace名 or default>"
PLAN_FILE="${LOG_DIR}/${TIMESTAMP}_${DIR_NAME}_${WORKSPACE}.tfplan"
LOG_FILE="${LOG_DIR}/${TIMESTAMP}_apply_${DIR_NAME}_${WORKSPACE}.log"

# ログヘッダー
cat > "$LOG_FILE" <<HEADER
# Command: <terraform or terragrunt> apply (via saved plan)
# Directory: <実行ディレクトリの絶対パス>
# Workspace: ${WORKSPACE}
# Plan file: ${PLAN_FILE}
# Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---
HEADER

# workspace がある場合は workspace select を先に実行（各 Bash 呼び出しはシェルが独立するため）
# -target が指定されている場合は -target=<resource> を付与（複数可、apply時に再指定は不要）
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> plan -out="$PLAN_FILE" [-target=<resource> ...] 2>&1 | tee -a "$LOG_FILE"

# 作成直後に checksum を記録し、PLAN_FILE のパスと checksum をこのステップの出力として明示する
PLAN_SHA256=$(shasum -a 256 "$PLAN_FILE" | awk '{print $1}')
echo "PLAN_FILE=${PLAN_FILE}"     | tee -a "$LOG_FILE"
echo "PLAN_SHA256=${PLAN_SHA256}" | tee -a "$LOG_FILE"
```

- `PLAN_FILE` は `~/terraform-logs/` 配下に保存する（リポジトリ配下に置かない。gitignore 対象かどうかを気にする必要がなくなる。plan ファイルには state のスナップショットが含まれるため機密情報を含みうる点に留意）
- plan の出力を確認し、期待した差分のみであることを確認する。想定外の差分がある場合はここで止めてユーザーに報告する
- **重要**: このステップの出力に表示された `PLAN_FILE` と `PLAN_SHA256` の値を、以降の Step 3・Step 4 で**そのまま文字列コピーして使う**。別の Bash 呼び出し（シェルが独立している）で `date` 等を使って再計算・再構成しては絶対にならない。値が手元にない場合は推測せず Step 2 をやり直す

## Step 3: 適用前の最終確認（必須の人間チェックポイント）

Step 2 の plan 出力から、以下を整理してユーザーに提示する:
- **env**: workspace名を人間が読める形に変換して明記する（例: dev→development, stg→staging, prd→production。workspace が無い場合は対象ディレクトリ名）
- **-target の有無**: 指定した場合は対象リソースのアドレス一覧も併記する
- **結果サマリー**: `Plan: N to add, N to change, N to destroy` の行
- **変更内容サマリー**: リソースごとの diff を簡潔に（何が add/change/destroy されるか、change の場合は変更前後の値）

その上で、**Step 2 で得た `PLAN_FILE` の絶対パスと `PLAN_SHA256`** を提示する。加えて、ユーザーが plan 全文を自分の手元で確認できる `show` コマンドを組み立て、**クリップボードにコピーする**（長いコマンドはチャット上で折り返され、コピペ時に途切れる/整形が崩れることがあるため、テキストとして貼るだけでなく必ずクリップボード経由でも渡す）:

```bash
# macOS の場合。<terraform or terragrunt> / -chdir の要否は Step 2 と揃える
echo '<terraform or terragrunt> -chdir=<実行ディレクトリの絶対パス> show "<PLAN_FILE>"' | pbcopy
```

コピー後、「plan 確認用のコマンドをクリップボードにコピーしました。ターミナルに貼り付けて全文を確認できます」とユーザーに伝える。

**明示的な適用の意思表示（「apply して」等）をチャット上で得るまで次に進まない**。この確認は毎回省略しない。特に prd 環境では必須。

## Step 4: 保存済み Plan を Apply

ユーザーの確認が得られたら、Step 2 で確定した `PLAN_FILE`（文字列コピーしたもの）に対して、apply 直前に checksum を再照合してから適用する。

```bash
# PLAN_FILE / EXPECTED_SHA256 は Step 2 の出力からそのまま埋め込む（再計算しない）
PLAN_FILE="<Step2で確認したPLAN_FILEの絶対パス>"
EXPECTED_SHA256="<Step2で確認したPLAN_SHA256>"

ACTUAL_SHA256=$(shasum -a 256 "$PLAN_FILE" | awk '{print $1}')
if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
  echo "ABORT: plan file checksum mismatch. expected=$EXPECTED_SHA256 actual=$ACTUAL_SHA256 file=$PLAN_FILE"
  exit 1
fi

# workspace がある場合は workspace select を先に実行
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> apply "$PLAN_FILE" 2>&1 | tee -a "$LOG_FILE"
```

- checksum が一致しない場合は**絶対に apply を実行せず**、ユーザーに報告して Step 2 からやり直す（ファイル取り違え・書き換えの検知）
- 対話プロンプトは発生しない（`-auto-approve` 不要）
- **`Saved plan is stale` / `Saved plan does not match the given state` エラーが出た場合**: 他の操作で state が変わっている。**Step 2 からやり直す**（古い plan を強制適用しない）

## Step 5: Apply 結果の検証

- exit code を確認する
- **変更が期待されるのに 0 changes が返った場合**: 次のステップに進まず、ユーザーに報告する
- エラーが発生した場合: エラー内容をそのまま報告し、ユーザーの指示を仰ぐ

## Step 6: Post-apply Plan（差分ゼロ確認）

Apply 成功後、同じディレクトリ・同じ workspace で（`-out` なしの通常の）plan を実行し、差分が出ないことを確認する。

```bash
# workspace がある場合は workspace select を先に実行
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> plan 2>&1
```

- `-target` なしで apply した場合: `No changes` が確認できれば OK
- `-target` で apply した場合: target 外のリソースに差分が残るのは想定通り。target 対象のリソースに差分が残っていないことを確認する
- **想定外の差分が残っている場合**: ユーザーに報告し、次のステップに進まない
- このログの保存は不要

## Step 7: 記録の投稿

投稿先が指定されている場合、以下のフォーマットで記録を投稿する。
**raw output はログファイルから読み取る。記憶やメモからの再構成は禁止。**

### フォーマット

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

### 投稿方法

PR コメントの場合:
```bash
gh pr comment <PR番号> --body "$(cat <<'EOF'
<上記フォーマットの内容>
EOF
)"
```

Issue コメントの場合:
```bash
gh issue comment <Issue番号> --body "$(cat <<'EOF'
<上記フォーマットの内容>
EOF
)"
```

## Step 8: 完了報告

ユーザーに以下を報告する:
- Apply 結果のサマリー
- Post-apply plan の結果（No changes であること）
- ログファイルのパス
- 記録の投稿先（投稿した場合）

## Step 9: 後片付け

plan ファイル（`$PLAN_FILE`）を削除する。state のスナップショットを含むため、不要になったら残さない。

```bash
rm -f "$PLAN_FILE"
```

## 注意事項

- apply の出力は**そのまま保存**する。別環境の出力を書き換えて使わない
- 並列で複数環境を apply する場合、全てのコマンドに `cd <absolute-path> &&` を含める
- 複数環境を順に apply する場合、各環境ごとに Step 2〜7 を完了してから次の環境に進む
