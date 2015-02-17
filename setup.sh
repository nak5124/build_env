#!/usr/bin/env bash


shdir=$(cd $(dirname $0);pwd)

dot_files=( .bashrc .gitconfig .hgrc .minttyrc .bash_profile .vimrc .bash_logout .tigrc .tmux.conf )
mg_patches=( mpfr isl cloog libiconv libintl bzip2 zlib binutils gcc nasm autoconf automake libtool )

# bat
cp -f ${shdir}/bat/* /
# buildscripts
ln -sf ${shdir}/buildscripts/*.sh $HOME
# dotfiles
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
# /etc
ln -sf ${shdir}/etc/* /etc
# gcc_build
if [ ! -d ${HOME}/gcc_build/scripts ] ; then
    mkdir -p ${HOME}/gcc_build/scripts
fi
ln -sf ${shdir}/gcc_build/*.sh ${HOME}/gcc_build
ln -sf ${shdir}/gcc_build/scripts/* ${HOME}/gcc_build/scripts
for dname in ${mg_patches[@]}
do
    if [ ! -d ${HOME}/gcc_build/patches/$dname ] ; then
        mkdir -p ${HOME}/gcc_build/patches/$dname
    fi
    ln -sf ${shdir}/gcc_build/patches/${dname}/* ${HOME}/gcc_build/patches/$dname
done
# /usr/local/bin
ln -sf ${shdir}/usr/local/bin/* /usr/local/bin
