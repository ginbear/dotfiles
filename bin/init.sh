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
.shellrc
.gitconfig
.gitignore
.snippets
.rspec
.fabricrc
fabfile.py
"

VIMFILELIST="
lightline.conf
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

# ディレクトリ配下の貼り直し
for FILE in ${VIMFILELIST};
do
    rm -rf ~/.vim/${FILE}
    mkdir ~/.vim
    ln -s ${PWD}/.vim/${FILE} ${HOME}/.vim/${FILE}
done

# go
mkdir ~/.go

# vim neobundle install
[ ! -e ~/.vim/bundle ] && git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim

# tssh deploy
ln -s ${PWD}/tssh/tssh /usr/local/bin
