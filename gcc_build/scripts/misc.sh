# get arch bit value
function get_arch_bit() {
    case "$1" in
        "i686" )
            echo "32"
            ;;
        "x86_64" )
            echo "64"
            ;;
        *)
            echo "64"
            ;;
    esac
}

# delete *.la files
function remove_la_files() {
    find "$1" -name "*.la" | xargs -rl1 rm -f
}

# strip files
function strip_files() {
    find "$1" -name "*.exe" | xargs -rl1 strip --preserve-dates --strip-all
    find "$1" -name "*.dll" | xargs -rl1 strip --preserve-dates --strip-unneeded
    find "$1" -name "*.a"   | xargs -rl1 strip --preserve-dates --strip-debug
}

# define readonly variable
function define_rov() {
    if [ "${1:-undefined}" = "undefined" -a "${1}" != "undefined" ] ; then
        cat << _EOT_ 1>&2
define_rov:
The 1st argument should be defined.
In addition, the 1st argument cannot be null character or a blank string.
_EOT_
        exit 1
    else
        eval readonly ${1}=${2}
    fi
}

# check wheter a variable is defined
function is_defined() {
    eval local tmp=$(echo '${'${1}'-undefined}')
    eval local tmp2=$(echo '${'${1}'}')
    if [ "${tmp}" = "undefined" -a "${tmp2}" != "undefined" ] ; then
        return 1
    else
        return 0
    fi
}

# delete empty dir
function del_empty_dir() {
    find "${1}" -type d -empty | xargs rmdir > /dev/null 2>&1
}
