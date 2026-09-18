#!/bin/bash

# herdr プラグインセットアップスクリプト
# 各エントリは herdr plugin install で確認したcommitに固定している

set -e

herdr plugin install tdi/herdr-worktree-setup --ref 4527a11bd5444dbce34c3d4f459b49d704cc12a7 --yes
herdr plugin install persiyanov/herdr-reviewr --ref 42ccaaa72176937181c82a91484f97466fb5ed59 --yes

echo "Done!"
