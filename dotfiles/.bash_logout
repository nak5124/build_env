
pacman -Sc --noconfirm > /dev/null

if [ -f /tmp/win32applist ] ; then
    declare -i i=0
    declare -a list
    sed -i '/^ *$/d' /tmp/win32applist
    while read line
    do
        list[i]=$line
        i=$((${i} + 1))
    done < /tmp/win32applist
    for (( i = 0; i < ${#list[*]}; i++ ))
    do
        win32kill ${list[${i}]} > /dev/null 2>&1
    done
    rm -f /tmp/win32applist
fi

if [ "${SHLVL}" = 1 ] ; then
    [ -x /usr/bin/clear ] && /usr/bin/clear
fi
