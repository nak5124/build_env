#!/usr/bin/env bash


declare plist
declare needed=""
declare opt
for opt in "${@}"
do
    case "${opt}" in
        --list=* | -l=* )
            plist="${opt#*=}"
            ;;
        -n )
            needed=" --needed"
            ;;
    esac
done

if [ -z "${plist}" ]; then
    declare -r shdir=$(cd $(dirname $BASH_SOURCE); pwd)
    plist=${shdir}/pacman_list
fi

if [ ! -f "${plist}" ]; then
    echo "pacman_list can not be found..."
    exit 1
fi

declare -i i=0
declare tmp
while read line
do
    tmp=(${line})
    case "${tmp[3]}" in
        *installed* )
            pl_array[i]=${tmp[1]}
            i=$((${i} + 1))
            ;;
    esac
done < $plist

pacman -S ${pl_array[@]} --force --noconfirm ${needed}
