#!/bin/bash


WORK_DIR="${HOME}/L-SMASH"
PREFIX_DIR="/usr/local/L-SMASH"
LOGS_DIR="${HOME}/log/lsmash"
LSMASH_VER="1.11.2"

echo_helpfile() {
    echo "muxer" > ${DEST_DIR}/lsmash_help.txt
    ./muxer 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "remuxer" >> ${DEST_DIR}/lsmash_help.txt
    ./remuxer 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "timelineeditor" >> ${DEST_DIR}/lsmash_help.txt
    ./timelineeditor 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "boxdumper" >> ${DEST_DIR}/lsmash_help.txt
    ./boxdumper 2>> ${DEST_DIR}/lsmash_help.txt
    dos2unix ${DEST_DIR}/lsmash_help.txt > /dev/null 2>&1
    cp -fa ${DEST_DIR}/lsmash_help.txt $PREFIX_DIR
}

build_lsmash() {
    clear; echo "Build L-SMASH git-master"

    if [ ! -d $WORK_DIR ] ; then
        cd $HOME
        git clone https://github.com/l-smash/l-smash.git L-SMASH
    fi
    cd $WORK_DIR

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsmash.hash
    git_rev >> ${LOGS_DIR}/lsmash.hash

    DEST_DIR=${PREFIX_DIR}/L-SMASH-${LSMASH_VER}-r`git_rev`-g`git_hash`
    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure L-SMASH ${arch}"
        ./configure > ${LOGS_DIR}/lsmash_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make L-SMASH ${arch}"
        make -j3 -O > ${LOGS_DIR}/lsmash_make_${arch}.log 2>&1 || exit 1
        echo "done"
        echo "===> copying files ${arch}"
        if [ "$arch" == "i686" ] ; then
            cp -fa ./cli/*.exe ${DEST_DIR}/win32/
            cp -fa ./LICENSE $DEST_DIR
            echo_helpfile
        else
            cp -fa ./cli/*.exe ${DEST_DIR}/x64/
            cp -fa ./cli/*.exe $PREFIX_DIR
        fi
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

build_lsmash

clear; echo "Everything has been successfully completed!"

