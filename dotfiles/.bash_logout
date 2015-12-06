
pacman -Sc --noconfirm > /dev/null

declare -r applist=/tmp/win32applist_"$$"

if [ -f "${applist}" ] ; then
    declare -i i=0
    declare -a list
    sed -i '/^ *$/d' "${applist}"
    while read line
    do
        list[i]=$line
        i=$((${i} + 1))
    done < "${applist}"
    for (( i = 0; i < ${#list[*]}; i++ ))
    do
        win32kill ${list[${i}]} > /dev/null 2>&1
    done
    rm -f "${applist}"
fi

if [ "${SHLVL}" = 1 ] ; then
    [ -x /usr/bin/clear ] && /usr/bin/clear
fi
