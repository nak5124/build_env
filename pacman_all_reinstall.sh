#/usr/bin/env bash


shdir=$(cd $(dirname $0);pwd)
plist=${shdir}/pacman_list

if [ ! -f $plist ] ; then
    echo "pacman_list can not be found..."
    exit 1
fi

i=0
while read line
do
    tmp=($line)
    if [ "${tmp[3]}" == "[installed]" ] ; then
        pl_array[i]=${tmp[1]}
        i=$((${i} + 1))
    fi
done < $plist

pacman -S ${pl_array[@]} --force --noconfirm

