# get arch bit value
function get_arch_bit() {
    case "$1" in
        "i686" )
            echo "32"
            ;;
        "x86_64" )
            echo "64"
            ;;
        * )
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
    find "$1" -name "*.exe"              | xargs -rl1 strip --preserve-dates --strip-all
    find "$1" -name "*.dll"              | xargs -rl1 strip --preserve-dates --strip-unneeded
    find "$1" -name "*.a" -o -name "*.o" | xargs -rl1 strip --preserve-dates --strip-debug
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

# download files
function dl_files() {
    local is_curl=false

    local -r prtcl=${1}
    local -r url=${2}
    local -r oname=${3}
    if [ -z "${prtcl}" -o -z "${url}" ] ; then
        echo 'dl_files: ${1} and ${2} should be specified!'
        exit 1
    fi

    case "${prtcl}" in
        ftp )
            local curl_opt="--fail --continue-at - --ftp-pasv --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30"
            is_curl=true
            ;;
        http | https )
            local curl_opt="--fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5 \
                            --speed-limit 1 --speed-time 30"
            is_curl=true
            ;;
        git )
            git clone $url $oname
            ;;
        * )
            printf "dl_files: %s is unknown protocol\n" $prtcl
            exit 1
    esac

    if $is_curl ; then
        if [ ! -z "${oname}" ] ; then
            curl $curl_opt -o $oname $url
        else
            curl $curl_opt --remote-name $url
        fi
    fi

    return 0
}

# decompress archive
function decomp_arch() {
    local fname=${1}
    if [ -z "${fname}" ] ; then
        echo 'decomp_arch: ${1} should be specified!'
        exit 1
    fi
    local ext='.'${fname##*.}
    local fname_noext=${fname%${ext}}
    local is_ok=false
    case "${ext}" in
        .gz )
            if [ "${fname_noext##*.}" = "tar" ] ; then
                tar xzf $fname
                is_ok=true
            fi
            ;;
        .bz2 )
            if [ "${fname_noext##*.}" = "tar" ] ; then
                tar xjf $fname
                is_ok=true
            fi
            ;;
        .lz | .lzma )
            if [ "${fname_noext##*.}" = "tar" ] ; then
                tar xf $fname
                is_ok=true
            fi
            ;;
        .xz )
            if [ "${fname_noext##*.}" = "tar" ] ; then
                tar Jxf $fname
                is_ok=true
            fi
            ;;
        * )
            printf "decomp_arch: %s is an unknown format.\n" $fname
            exit 1
    esac

    if $is_ok ; then
        return 0
    else
        printf "decomp_arch: %s is not a tar archive.\n" $fname
        exit 1
    fi
}

# arch optimization flags
function arch_optflags() {
    case "$1" in
        "i686" )
            echo "-march=i686 -mtune=generic"
            ;;
        "x86_64" )
            echo "-march=x86-64 -mtune=generic"
            ;;
        * )
            echo "-mtune=generic"
            ;;
    esac
}

# add large-address-aware flag
function add_laa() {
    find "$1" -name "*.exe" | xargs -rl1 genpeimg -p +l
}
