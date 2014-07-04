#!/bin/sh

# refs. https://github.com/glidenote/dotfiles/blob/master/bin/init.sh
# ghq で get してきて、
# sh bin/init.sh 
# する事を想定

# gitで管理するファイルリスト
FILELIST="
.bash_profile
.vimrc
.gvimrc
.zshrc
.tmux.conf
.peco
"

# 必要ディレクトリの作成
# cd ~
# mkdir bin tmp work src

# 既存ディレクトリ、ファイルを待避させる
if [ ! -e ~/old_files ]; then
    mkdir ~/old_files
    for FILE in ${FILELIST};
    do
        mv ~/${FILE} ~/old_files/
    done
fi

# link張り直し
for FILE in ${FILELIST};
do
    rm -rf ~/${FILE}
    ln -s ${PWD}/${FILE} ${HOME}/${FILE}
done

# install peco and ghq
# export GOPATH=$HOME
# go get github.com/peco/peco/cmd/peco
# go get github.com/motemen/ghq

# NeoBundleinstall 
# mkdir -p ~/.vim/bundle
# git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
# git clone https://github.com/Shougo/vimproc ~/.vim/bundle/vimproc
# vim +NeoBundleInstall! +qall
