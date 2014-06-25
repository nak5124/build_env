#!/usr/bin/env bash


LOGS_DIR=${HOME}/logs/x264
if [ ! -d $LOGS_DIR ] ; then
    mkdir -p $LOGS_DIR
fi

build_x264() {
    clear; echo "Build x264"

    if [ ! -d ${HOME}/OSS/videolan/x264 ] ; then
        cd ${HOME}/OSS/videolan
        git clone git://github.com/nak5124/x264.git
    fi
    cd ${HOME}/OSS/videolan/x264

    git clean -fdx > /dev/null 2>&1
    git reset --hard > /dev/null 2>&1
    git pull --rebase > /dev/null 2>&1
    git_hash > ${LOGS_DIR}/x264.hash
    git_rev >> ${LOGS_DIR}/x264.hash

    local SAMPLE_FILES="${HOME}/y4m/deadline_cif.y4m \
                        ${HOME}/y4m/foreman_cif.y4m  \
                        ${HOME}/y4m/soccer_4cif.y4m"
    local patches_num=23

    source cpath x86_64
    for bitdepth in 8 10
    do
        for buildtype in all lite
        do
            if [ "$buildtype" == "all" ] ; then
                local _format="all"
                local _opt=""
                if [ "$bitdepth" -eq 8 ] ; then
                    local _clopt=""
                    local _target="Full 8bit"
                else
                    local _clopt="--disable-opencl"
                    local _target="Full 10bit"
                fi
            else
                local _format="420"
                local _opt="--disable-interlaced --disable-swscale \
                            --disable-lavf"
                local _clopt="--disable-opencl"
                if [ "$bitdepth" -eq 8 ] ; then
                    local _target="Lite 8bit"
                else
                    local _target="Lite 10bit"
                fi
            fi

            echo "===> configure x264 ${_target}"
            PKG_CONFIG_PATH=${HOME}/local/x86_64/lib/pkgconfig \
            ./configure ${_clopt}                              \
                        --enable-win32thread                   \
                        --bit-depth=$bitdepth                  \
                        --chroma-format=$_format               \
                        --enable-strip                         \
                        ${_opt}                                \
            > ${LOGS_DIR}/x264_config_${bitdepth}bit_${buildtype}.log 2>&1 \
                || exit 1
            echo "done"

            make clean > /dev/null 2>&1
            echo "===> make fprofiled x264 ${_target}"
            make -j9 -O fprofiled VIDS="$SAMPLE_FILES" \
                > ${LOGS_DIR}/x264_make_${bitdepth}bit_${buildtype}.log 2>&1 \
                    || exit 1
            echo "done"

            if [ "$bitdepth" -eq 8 ] && [ "$buildtype" == "all" ] ; then
                local X264_REVISION=$(x264 --version | grep "x264" \
                    | awk '{print $2}' | awk -F . '{print $3}'     \
                    | awk -F + '{print $1}')
                local DEST_DIR=${HOME}/local/dist/x264/x264_r${X264_REVISION}_x64
                if [ ! -d ${DEST_DIR}/lite ] ; then
                    mkdir -p ${DEST_DIR}/lite
                fi
            fi

            echo "===> copy x264 ${_target}"
            if [ "$bitdepth" -eq 8 ] ; then
                if [ "$buildtype" == "all" ] ; then
                    cp -fa ./x264.exe ${DEST_DIR}/x264_x64.exe
                    ./x264.exe --fullhelp > ${DEST_DIR}/x264_x64_help.txt
                else
                    cp -fa ./x264.exe ${DEST_DIR}/lite/x264_x64_lite.exe
                    ./x264.exe --fullhelp \
                        > ${DEST_DIR}/lite/x264_x64_lite_help.txt
                fi
            else
                if [ "$buildtype" == "all" ] ; then
                    cp -fa ./x264.exe ${DEST_DIR}/x264_x64-10bit.exe
                    ./x264.exe --fullhelp > ${DEST_DIR}/x264_x64-10bit_help.txt
                else
                    cp -fa ./x264.exe ${DEST_DIR}/lite/x264_x64_lite-10bit.exe
                    ./x264.exe --fullhelp \
                        > ${DEST_DIR}/lite/x264_x64_lite-10bit_help.txt
                fi
            fi
            echo "done"
            make distclean > /dev/null 2>&1
        done
    done

    git archive --format=tar --prefix=x264_r${X264_REVISION}_src/ HEAD \
        | lzip -9 -o ${HOME}/local/dist/x264/x264_r${X264_REVISION}_src.tar
    git format-patch HEAD~$patches_num -o x264_r${X264_REVISION}_patches
    tar cf - x264_r${X264_REVISION}_patches \
        | lzip -9 -o \
            ${HOME}/local/dist/x264/x264_r${X264_REVISION}_patches.tar -
    cp -fa ./COPYING $DEST_DIR

    cd $HOME
    return 0
}

build_x264

clear; echo "Everything has been successfully completed!"
