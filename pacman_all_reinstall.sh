#!/usr/bin/env bash


for opt in "$@"
do
    case "${opt}" in
        --list=* | -l=* )
            plist="${opt#*=}"
            ;;
    esac
done

if [ -z "${plist}" ] ; then
    shdir=$(cd $(dirname $0);pwd)
    plist=${shdir}/pacman_list
fi

if [ ! -f "${plist}" ] ; then
    echo "pacman_list can not be found..."
    exit 1
fi

i=0
while read line
do
    tmp=($line)
    case "${tmp[3]}" in
        "*installed*" )
            pl_array[i]=${tmp[1]}
            i=$((${i} + 1))
            ;;
    esac
done < $plist

if [ "$1" == "-n" ] ; then
    local opt=" --needed"
else
    local opt=""
fi
pacman -S ${pl_array[@]} --force --noconfirm ${opt}
