---
name: terraform-apply
description: Terraform/Terragrunt applyを安全に実行し、検証・記録まで一貫して行う
user_invocable: true
---

# Terraform Apply（安全実行）

Terraform または Terragrunt の apply を実行し、出力保存 → 差分検証 → 記録投稿まで一貫して行う。

## 前提条件

- `/terraform-plan` が実行済みで、ユーザーが適用方針（全適用 or `-target`）を確認済みであること
- plan 未実施の場合は `/terraform-plan` を先に実行するよう案内する

## Step 1: 事前確認

ユーザーに以下を確認する（引数で指定済みの場合はスキップ）:
- 実行ディレクトリ（絶対パス）
- terraform か terragrunt か
- workspace（該当する場合）
- 記録の投稿先（PR コメント / Issue コメント / なし）
- `-auto-approve` で実行するか（デフォルトは確認あり）
- `-target` リソース一覧（plan で `-target` 適用が選択された場合）

## Step 2: Apply 実行とログ保存

```bash
LOG_DIR="$HOME/terraform-logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%H-%M-%S)
DIR_NAME=$(basename <実行ディレクトリ>)
WORKSPACE="<workspace名 or default>"
LOG_FILE="${LOG_DIR}/${TIMESTAMP}_apply_${DIR_NAME}_${WORKSPACE}.log"

# ログヘッダー
cat > "$LOG_FILE" <<HEADER
# Command: <terraform or terragrunt> apply
# Directory: <実行ディレクトリの絶対パス>
# Workspace: ${WORKSPACE}
# Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---
HEADER

# Apply 実行（必ず cd で対象ディレクトリに移動してから実行）
# workspace がある場合は workspace select を先に実行
# -auto-approve はユーザーが承認した場合のみ付与
# -target が指定されている場合は -target=<resource> を付与（複数可）
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> apply [-target=<resource> ...] 2>&1 | tee -a "$LOG_FILE"
```

## Step 3: Apply 結果の検証

- exit code を確認する
- **変更が期待されるのに 0 changes が返った場合**: 次のステップに進まず、ユーザーに報告する
- エラーが発生した場合: エラー内容をそのまま報告し、ユーザーの指示を仰ぐ

## Step 4: Post-apply Plan（差分ゼロ確認）

Apply 成功後、同じディレクトリ・同じ workspace で plan を実行し、差分が出ないことを確認する。

```bash
# workspace がある場合は workspace select を先に実行（各 Bash 呼び出しはシェルが独立するため）
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> workspace select <workspace> && <terraform or terragrunt> plan 2>&1
```

- `-target` なしで apply した場合: `No changes` が確認できれば OK
- `-target` で apply した場合: target 外のリソースに差分が残るのは想定通り。target 対象のリソースに差分が残っていないことを確認する
- **想定外の差分が残っている場合**: ユーザーに報告し、次のステップに進まない
- このログの保存は不要

## Step 5: 記録の投稿

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

## Step 6: 完了報告

ユーザーに以下を報告する:
- Apply 結果のサマリー
- Post-apply plan の結果（No changes であること）
- ログファイルのパス
- 記録の投稿先（投稿した場合）

## 注意事項

- apply の出力は**そのまま保存**する。別環境の出力を書き換えて使わない
- 並列で複数環境を apply する場合、全てのコマンドに `cd <absolute-path> &&` を含める
- 複数環境を順に apply する場合、各環境ごとに Step 2〜5 を完了してから次の環境に進む
