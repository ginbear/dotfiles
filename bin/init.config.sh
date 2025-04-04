#!/bin/sh

# gitで管理するファイルリスト
FILELIST="
karabiner
raycast
"

# 必要ディレクトリの作成
# cd ~
# mkdir bin tmp work src
if [ ! -e ~/.config ]; then
	mkdir ~/.config
fi

# 既存ディレクトリ、ファイルを待避させる
if [ ! -e ~/old_config ]; then
    mkdir ~/old_config
    for FILE in ~/.config/${FILELIST};
    do
        mv ~/.cofngi/${FILE} ~/old_config/
    done
fi

# link張り直し
for FILE in ${FILELIST};
do
    rm -rf ~/.config/${FILE}
    ln -s ${PWD}/.config/${FILE} ~/.config/${FILE}
done

