---
name: insights-feedback
description: /insight の結果を分析し、CLAUDE.md の改善提案を生成する。「インサイト改善」「CLAUDE.md フィードバック」「設定改善」などと指示された場合に実行。
tools: Read, Glob, Grep, Bash, Edit
---

# Insights Feedback Loop

`/insight` のセッション分析を元に、CLAUDE.md 系ファイルの改善提案を行うスキル。

## 前提

- dotfiles は chezmoi で管理されている
- chezmoi ソースディレクトリ: `~/ghq/github.com/ginbear/dotfiles`
- `~/` 配下のファイルを直接編集しない。必ず chezmoi ソースディレクトリ内を編集する

## 対象ファイル

### 個人設定（dotfiles リポジトリ）

chezmoi ソースディレクトリ内を直接編集する。

| ファイル | パス | 用途 |
|---------|------|------|
| CLAUDE.md | `dot_claude/CLAUDE.md` | グローバル設定（参照のみ） |
| CLAUDE_PERSONAL.md | `dot_claude/personal/CLAUDE_PERSONAL.md` | 個人設定 |

### チーム設定（別リポジトリ）

CLAUDE_TEAM.md はチーム共有の別リポジトリで管理されている。
ローカルでは `~/.claude/team/` に配置されているので、以下のコマンドでリポジトリ情報を取得する:

```bash
git -C ~/.claude/team remote -v
git -C ~/.claude/team branch --show-current
```

チーム設定への変更はブランチ作成 → PR で提案する。

## ワークフロー

### Phase 1: Insight 収集

**`/insight` は Claude Code の組み込みCLIコマンドであり、スキルから直接実行できない。**
ユーザーに事前実行を促す必要がある。

#### 手順

1. まず、会話履歴に `/insight` の実行結果が含まれているか確認する
2. **含まれていない場合**: 以下のメッセージでユーザーに事前実行を促し、スキルの実行を一時停止する

   > `/insight` の実行結果が必要です。先に `/insight` を実行して、その結果をこのセッションに貼り付けてください。
   > 実行後、再度 `/insights-feedback` を実行するか、結果を貼り付けてください。

3. **含まれている場合**: insight の結果からデータの対象期間を特定し、レポートのサマリーに明示する

#### insight から取得すべき情報
- よく使うツール・パターン
- 失敗・リトライが多かった操作
- 頻出するタスクの種類
- セッションの効率性に関する指標
- **データの対象期間**（いつからいつまでのセッションが対象か）

### Phase 2: 現状の CLAUDE.md と rules を読み込む

以下のファイルを読み込んで現状を把握する:

```bash
# chezmoi ソースディレクトリ内
cat ~/ghq/github.com/ginbear/dotfiles/dot_claude/CLAUDE.md
cat ~/ghq/github.com/ginbear/dotfiles/dot_claude/personal/CLAUDE_PERSONAL.md
```

rules ファイルも読み込む:
```bash
ls ~/ghq/github.com/ginbear/dotfiles/dot_claude/rules/
# 各 .md ファイルを読み込む（シンボリックリンク先のチーム rules も含む）
```

チーム設定も参照用に読む:
```bash
cat ~/.claude/team/dot_claude/CLAUDE_TEAM.md
ls ~/.claude/team/dot_claude/rules/
```

### Phase 3: 分析 & 改善提案の生成

insight の結果と現在の設定を照らし合わせ、以下の観点で分析する:

#### 追加すべきもの
- **繰り返し発生するミスパターン** → 禁止事項・注意事項として追記
- **頻出ワークフロー** → 手順やスキル化の提案
- **暗黙知の明文化** → よく使うコマンド、ファイルパス、環境固有の情報

#### 修正すべきもの
- **実態と乖離した記述** → 現在のワークフローに合わせて更新
- **効果が薄い指示** → より具体的・実行可能な表現に変更

#### 削除すべきもの
- **冗長・重複した記述** → 統合して簡素化
- **もう使っていないツール/ワークフローの記述** → 削除

#### 配置先の判断（CLAUDE.md vs .claude/rules/）
- **プロジェクト概要、環境情報、ワークフロー全般** → CLAUDE.md 系（セッション開始時に注入）
- **特定ファイル種別に紐づくコーディング規約・禁止事項** → `.claude/rules/*.md`（該当ファイル初出時に注入）
- rules には YAML frontmatter の `paths` で適用条件を指定する（例: `**/*.tf` で Terraform ファイルのみ）
- 既存の rules ファイルに追記すべきか、新規 rules ファイルを作るべきかも判断する

#### 構造改善
- **肥大化の兆候** → セクション分割、別ファイル化（rules 移行を含む）の提案
- **優先度の並び替え** → 重要な指示を上位に配置

### Phase 4: レポート出力

以下のフォーマットで改善提案を出力する。**必ず変更を適用する前にレポートを提示すること。**

```markdown
## Insights Feedback Report

### サマリー
- データ対象期間: YYYY-MM-DD 〜 YYYY-MM-DD
- 分析セッション数: X
- 改善提案数: X (追加: X / 修正: X / 削除: X)
- 推定効果: [高/中/低]

### 提案一覧

#### 1. [追加/修正/削除] 提案タイトル
**根拠**: insight でこういうパターンが見つかった
**対象**: CLAUDE_PERSONAL.md / .claude/rules/xxx.md
**変更内容**:
```diff
+ 追加する行
- 削除する行
```

#### 2. ...
```

### Phase 5: ユーザー承認 & 適用

レポートを提示し、ユーザーに承認を求める。承認された提案のみ適用する。

#### 個人設定（CLAUDE_PERSONAL.md 等）

1. **chezmoi ソースディレクトリ内のファイルを Edit ツールで編集**する
2. `chezmoi apply` は実行しない（ユーザーが手動で行う）
3. 適用後、git diff を表示して変更内容を確認できるようにする

#### チーム設定（CLAUDE_TEAM.md）

1. `~/.claude/team/` でブランチを作成する
2. CLAUDE_TEAM.md を Edit ツールで編集する
3. コミットして push する
4. `gh pr create` で PR を作成する
5. PR の URL をユーザーに表示する

```bash
# ブランチ作成・編集・PR の流れ
cd ~/.claude/team
git checkout -b insights-feedback/$(date +%Y%m%d)
# ... Edit で編集 ...
git add dot_claude/CLAUDE_TEAM.md
git commit -m "docs: Update CLAUDE_TEAM.md based on insights feedback"
git push -u origin HEAD
gh pr create --title "docs: CLAUDE_TEAM.md improvements from insights" --body "..."
```

## 注意事項

- CLAUDE.md の肥大化を防ぐため、1回の改善で追加する行数は必要最小限にする
- 「やってほしいこと」より「やりがちだけどやめてほしいこと」の方が効果が高い傾向がある。禁止事項の追記を優先する
- 既存の記述と矛盾する提案は、既存側の修正も合わせて提案する
- チーム設定の PR にはブランチフローがある場合がある。`~/.claude/team/` のデフォルトブランチとリポジトリの運用ルールを確認してから作業する
