#!/usr/bin/env bash


shdir=$(cd $(dirname $0);pwd)
dot_files=( .bashrc .gitconfig .hgrc .minttyrc .profile .vimrc )
mg_patches=( autoconf automake binutils bzip2 cloog gcc-4.9.0 libiconv \
             libtool mpfr )
ln -sf ${shdir}/bat/mintty* /
cp -f ${shdir}/bat/autorebase.bat /
ln -sf ${shdir}/buildscripts/* $HOME
for fname in ${dot_files[@]}
do
    ln -sf ${shdir}/dotfiles/$fname ${HOME}/$fname
done
if [ ! -d ${HOME}/.config/mc ] ; then
    mkdir -p ${HOME}/.config/mc
fi
ln -sf ${shdir}/dotfiles/.config/mc/* ${HOME}/.config/mc
if [[ ! -d ${HOME}/.vim/{colors,syntax} ]] ; then
    mkdir -p ${HOME}/.vim/{colors,syntax}
fi
ln -sf ${shdir}/dotfiles/.vim/colors/* ${HOME}/.vim/colors
ln -sf ${shdir}/dotfiles/.vim/syntax/* ${HOME}/.vim/syntax
ln -sf ${shdir}/etc/* /etc
if [ ! -d ${HOME}/gcc_build/scripts ] ; then
    mkdir -p ${HOME}/gcc_build/scripts
fi
ln -sf ${shdir}/gcc_build/scripts/* ${HOME}/gcc_build/scripts
for dname in ${mg_patches[@]}
do
    if [ ! -d ${HOME}/gcc_build/patches/$dname ] ; then
        mkdir -p ${HOME}/gcc_build/patches/$dname
    fi
    ln -sf ${shdir}/gcc_build/patches/${dname}/* \
        ${HOME}/gcc_build/patches/$dname
done
ln -sf ${shdir}/usr/bin/* /usr/bin
