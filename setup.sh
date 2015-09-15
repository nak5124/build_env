#!/usr/bin/env bash


shdir=$(cd $(dirname $0);pwd)

dot_files=( .bash_logout .bash_profile .bashrc .bash_alias .bash_func .gitconfig .hgrc .inputrc .minttyrc .tigrc .tmux.conf .vimrc .vimshrc )
etc_files=( DIR_COLORS fstab makepkg.conf makepkg_mingw32_Takuan.conf makepkg_mingw64_Takuan.conf pacman.conf profile )
pd_files=( mirrorlist.mingw32 mirrorlist.mingw64 mirrorlist.msys repman.conf )
mg_patches=( mpfr isl libiconv zlib binutils gcc nasm autoconf automake libtool config )

# bat
cp -fa ${shdir}/bat/* /
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
for fname in ${etc_files[@]}
do
    ln -sf ${shdir}/etc/$fname /etc/$fname
done
for fname in ${pd_files[@]}
do
    ln -sf ${shdir}/etc/pacman.d/$fname /etc/pacman.d/$fname
done
# gcc_build
if [ ! -d ${HOME}/gcc_build/scripts ] ; then
    mkdir -p ${HOME}/gcc_build/scripts
fi
ln -sf ${shdir}/gcc_build/*.sh ${HOME}/gcc_build
ln -sf ${shdir}/gcc_build/scripts/* ${HOME}/gcc_build/scripts
rm -fr ${HOME}/gcc_build/patches
for dname in ${mg_patches[@]}
do
    if [ ! -d ${HOME}/gcc_build/patches/$dname ] ; then
        mkdir -p ${HOME}/gcc_build/patches/$dname
    fi
    ln -sf ${shdir}/gcc_build/patches/${dname}/* ${HOME}/gcc_build/patches/$dname
done
# /usr/local/bin
ln -sf ${shdir}/usr/local/bin/* /usr/local/bin
