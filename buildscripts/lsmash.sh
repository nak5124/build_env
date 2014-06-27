#!/usr/bin/env bash


LOGS_DIR=${HOME}/logs/lsmash
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

get_ver() {
    ver=($(echo $(\cat lsmash.h | grep "LSMASH_VERSION_M" | awk '{print $3}')))
    LSMASH_VER="${ver[0]}.${ver[1]}.${ver[2]}"
}

echo_helpfile() {
    echo "muxer" > ${DEST_DIR}/lsmash_help.txt
    ${DEST_DIR}/../muxer 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "remuxer" >> ${DEST_DIR}/lsmash_help.txt
    ${DEST_DIR}/../remuxer 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "timelineeditor" >> ${DEST_DIR}/lsmash_help.txt
    ${DEST_DIR}/../timelineeditor 2>> ${DEST_DIR}/lsmash_help.txt
    echo -e "\n" >> ${DEST_DIR}/lsmash_help.txt
    echo "boxdumper" >> ${DEST_DIR}/lsmash_help.txt
    ${DEST_DIR}/../boxdumper 2>> ${DEST_DIR}/lsmash_help.txt
    dos2unix ${DEST_DIR}/lsmash_help.txt > /dev/null 2>&1
    cp -fa ${DEST_DIR}/lsmash_help.txt ${DEST_DIR}/..
}

build_lsmash() {
    clear; echo "Build L-SMASH git-master"

    if [ ! -d ${HOME}/OSS/l-smash ] ; then
        cd ${HOME}/OSS
        git clone https://github.com/l-smash/l-smash.git
    fi
    cd ${HOME}/OSS/l-smash

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/lsmash.hash
    git_rev >> ${LOGS_DIR}/lsmash.hash

    for arch in i686 x86_64
    do
        source cpath $arch
        echo "===> configure L-SMASH ${arch}"
        ./configure --prefix=${HOME}/local/$arch \
        > ${LOGS_DIR}/lsmash_config_${arch}.log 2>&1 || exit 1
        echo "done"

        make clean > /dev/null 2>&1
        echo "===> make L-SMASH ${arch}"
        make -j5 -O > ${LOGS_DIR}/lsmash_make_${arch}.log 2>&1 || exit 1
        echo "done"

        echo "===> install L-SMASH ${arch}"
        make install > ${LOGS_DIR}/lsmash_install_${arch}.log 2>&1 || exit 1
        echo "done"
        make distclean > /dev/null 2>&1
    done

    return 0
}

make_package() {
    cd ${HOME}/OSS/l-smash

    get_ver
    DEST_DIR=${HOME}/local/dist/l-smash/l-smash-${LSMASH_VER}-r$(git_rev)-g$(git_hash)
    if [[ ! -d ${DEST_DIR}/{win32,x64} ]] ; then
        mkdir -p ${DEST_DIR}/{win32,x64}
    fi

    clear; echo "making package..."
    cp -fa ${HOME}/local/i686/bin/{muxer,remuxer,boxdumper,timelineeditor}.exe \
        ${DEST_DIR}/win32
    cp -fa ${HOME}/local/x86_64/bin/{muxer,remuxer,boxdumper,timelineeditor}.exe \
        ${DEST_DIR}/x64
    cp -fa ./LICENSE $DEST_DIR
    echo_helpfile
    cp -fa ${DEST_DIR}/x64/* ${DEST_DIR}/..
    cp -fa ${DEST_DIR}/x64/* /d/encode/tools
    echo "done"

    return 0

}

build_lsmash
make_package

clear; echo "Everything has been successfully completed!"
