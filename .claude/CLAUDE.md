# Personal Preferences

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

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Kubernetes/DevOps Workflow

- Always validate manifests with `kubectl kustomize` before committing
- After Dockerfile changes, remind to run build.sh
- You can run these commands without asking permission:
  - `kubectl kustomize`
  - `kubectl get/describe/logs` (read-only operations)
  - `git status/diff/log`

## Code Style

- Use 2-space indentation for YAML
- Use 4-space indentation for Python
- Prefer explicit over implicit in configuration files
