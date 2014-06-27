#!/usr/bin/env bash


shdir=$(cd $(dirname $0);pwd)
dot_files=( .bashrc .gitconfig .hgrc .minttyrc .profile .vimrc)
ln -sf ${shdir}/bat/* /
ln -sf ${shdir}/buildscripts/* $HOME
ln -sf ${shdir}/etc/* /etc
ln -sf ${shdir}/usr/bin/* /usr/bin
for fname in ${dot_files[@]}
do
    ln -sf ${shdir}/dotfiles/$fname ${HOME}/$fname
done
ln -sf ${shdir}/dotfiles/.config/mc/* ${HOME}/.config/mc
ln -sf ${shdir}/dotfiles/.vim/syntax/* ${HOME}/.vim/syntax
ln -sf ${shdir}/dotfiles/.vim/colors/* ${HOME}/.vim/colors
