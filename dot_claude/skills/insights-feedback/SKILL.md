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

`/insight` を実行してセッション分析を取得する。

取得すべき情報:
- よく使うツール・パターン
- 失敗・リトライが多かった操作
- 頻出するタスクの種類
- セッションの効率性に関する指標

### Phase 2: 現状の CLAUDE.md を読み込む

以下のファイルを読み込んで現状を把握する:

```bash
# chezmoi ソースディレクトリ内
cat ~/ghq/github.com/ginbear/dotfiles/dot_claude/CLAUDE.md
cat ~/ghq/github.com/ginbear/dotfiles/dot_claude/personal/CLAUDE_PERSONAL.md
```

チーム設定も参照用に読む:
```bash
cat ~/.claude/team/dot_claude/CLAUDE_TEAM.md
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

#### 構造改善
- **肥大化の兆候** → セクション分割、別ファイル化の提案
- **優先度の並び替え** → 重要な指示を上位に配置

### Phase 4: レポート出力

以下のフォーマットで改善提案を出力する。**必ず変更を適用する前にレポートを提示すること。**

```markdown
## Insights Feedback Report

### サマリー
- 分析セッション数: X
- 改善提案数: X (追加: X / 修正: X / 削除: X)
- 推定効果: [高/中/低]

### 提案一覧

#### 1. [追加/修正/削除] 提案タイトル
**根拠**: insight でこういうパターンが見つかった
**対象**: CLAUDE_PERSONAL.md
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
