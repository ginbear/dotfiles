---
name: terraform-plan
description: Terraform/Terragrunt planを安全に実行し、出力をローカルに保存してサマリーを提示する
user_invocable: true
---

# Terraform Plan（安全実行）

Terraform または Terragrunt の plan を **target なし**で実行し、今回の変更だけでなく既存のドリフトも含めた全差分を検出する。

## Step 1: 事前確認

ユーザーに以下を確認する（引数で指定済みの場合はスキップ）:
- 実行ディレクトリ（絶対パス）
- terraform か terragrunt か
- workspace（該当する場合）

## Step 2: Plan 実行（target なし）とログ保存

**必ず `-target` なしで実行する。** 今回の変更以外の既存ドリフトを検出するため。

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

## Step 4: 差分の分類とサマリー報告

plan の出力を分析し、以下の 2 カテゴリに分類してユーザーに提示する:

### 今回の変更（意図した差分）
- 今回のコード変更に対応するリソースの追加/変更/削除

### 既存の差分（意図しないドリフト）
- 今回の変更とは無関係に検出されたリソースの差分
- 例: 手動変更による state とのズレ、別作業の未適用分など

### 報告に含める情報
1. 追加/変更/削除されるリソース数（全体）
2. 今回の変更に対応するリソース一覧
3. 既存ドリフトのリソース一覧（ある場合）
4. ログファイルのパス

## Step 5: ユーザーに適用方針を確認

**既存のドリフトがない場合:**
- そのまま apply してよいか確認する

**既存のドリフトがある場合:**
- 以下の選択肢を提示し、ユーザーの判断を仰ぐ:
  1. **`-target` で今回の変更のみ適用** — 既存ドリフトには触れない
  2. **全差分をまとめて適用** — 既存ドリフトも含めて apply する
  3. **適用を保留** — ドリフトの原因を調査してから判断する

**ユーザーの確認を得るまで apply や次の環境の作業に進まない。**

ユーザーが `-target` を選択した場合、対象リソースのアドレス一覧を提示して確認を取る。

## 注意事項

- plan の出力は**そのまま保存**する。別環境の出力を書き換えて使わない
- 並列で複数環境を plan する場合、全てのコマンドに `cd <absolute-path> &&` を含める
