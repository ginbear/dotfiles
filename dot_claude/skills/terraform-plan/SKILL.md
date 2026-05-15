---
name: terraform-plan
description: Terraform/Terragrunt planを安全に実行し、出力をローカルに保存してサマリーを提示する
user_invocable: true
---

# Terraform Plan（安全実行）

Terraform または Terragrunt の plan を実行し、出力をローカルに保存した上でユーザーにサマリーを提示する。

## Step 1: 事前確認

ユーザーに以下を確認する（引数で指定済みの場合はスキップ）:
- 実行ディレクトリ（絶対パス）
- terraform か terragrunt か
- workspace（該当する場合）

## Step 2: Plan 実行とログ保存

ログの保存先は `~/terraform-logs/YYYY-MM-DD/` とする。

```bash
LOG_DIR="$HOME/terraform-logs/$(date +%Y-%m-%d)"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%H-%M-%S)
DIR_NAME=$(basename <実行ディレクトリ>)
WORKSPACE="<workspace名 or default>"
LOG_FILE="${LOG_DIR}/${TIMESTAMP}_plan_${DIR_NAME}_${WORKSPACE}.log"

# ログヘッダー
cat > "$LOG_FILE" <<HEADER
# Command: <terraform or terragrunt> plan
# Directory: <実行ディレクトリの絶対パス>
# Workspace: ${WORKSPACE}
# Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---
HEADER

# Plan 実行（必ず cd で対象ディレクトリに移動してから実行）
# workspace がある場合は workspace select を先に実行（各 Bash 呼び出しはシェルが独立するため）
cd <実行ディレクトリの絶対パス> && <terraform or terragrunt> plan 2>&1 | tee -a "$LOG_FILE"
```

## Step 3: 結果の検証

- plan の exit code を確認する
- **変更が期待されるのに 0 changes が返った場合**: 次のステップに進まず、ユーザーに報告して指示を仰ぐ
- エラーが発生した場合: エラー内容をそのまま報告する

## Step 4: サマリー報告

以下の情報をユーザーに提示する:

1. 追加/変更/削除されるリソース数
2. 主要な変更リソースの一覧
3. ログファイルのパス

**ユーザーの確認を得るまで apply や次の環境の作業に進まない。**

## 注意事項

- plan の出力は**そのまま保存**する。別環境の出力を書き換えて使わない
- 並列で複数環境を plan する場合、全てのコマンドに `cd <absolute-path> &&` を含める
