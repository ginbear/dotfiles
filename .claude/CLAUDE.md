# Personal Preferences

# Private Settings (company-specific)
@~/.claude/CLAUDE.local.md

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

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- After Dockerfile changes, remind to run build.sh
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
