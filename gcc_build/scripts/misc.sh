# Get arch bit value.
function get_arch_bit() {
    # $1: arch
    # _ret: bit nums of arch

    local _ret
    case "${1}" in
        i686 )
            _ret=32
            ;;
        x86_64 )
            _ret=64
            ;;
        * )
            printf "get_arch_bit, Unknown Arch: '%s'\n" "${1}"
            echo '...exit'
            exit 1
            ;;
    esac

    echo "${_ret}"
}

# Remove empty dirs.
function remove_empty_dirs() {
    # $1: target dir

    find "${1}" -type d -empty | xargs rmdir > /dev/null 2>&1
}

# Remove *.la files.
function remove_la_files() {
    # $1: target dir

    find "${1}" -name "*.la" | xargs -rl1 rm -f
}

# Strip files.
function strip_files() {
    # $1: target dir

    find "${1}" -type f -name "*.exe"                       | xargs -rl1 /usr/bin/strip --preserve-dates --strip-all
    find "${1}" -type f -name "*.dll"                       | xargs -rl1 /usr/bin/strip --preserve-dates --strip-unneeded
    find "${1}" -type f -a \( -name "*.a" -o -name "*.o" \) | xargs -rl1 /usr/bin/strip --preserve-dates --strip-debug
}

# Download files.
function dl_files() {
    # $1: protocol
    # $2: url
    # $3: output dir/file name

    local -r _prtcl=${1}
    local -r _url=${2}
    local -r _oname=${3}

    local _is_curl=false

    if [ -z "${_prtcl}" -o -z "${_url}" ]; then
        echo 'dl_files: ${1} and ${2} should be specified!'
        echo '...exit'
        exit 1
    fi

    case "${_prtcl}" in
        ftp )
            local _curl_opt=(--fail --continue-at - --ftp-pasv --retry 10 --retry-delay 5 --speed-limit 1 --speed-time 30)
            _is_curl=true
            ;;
        http | https )
            local _curl_opt=(--fail --location --max-redirs 2 --continue-at - --retry 10 --retry-delay 5
                             --speed-limit 1 --speed-time 30)
            _is_curl=true
            ;;
        git )
            git clone "${_url}" "${_oname}"
            ;;
        * )
            printf "dl_files, Unknown Protocol: '%s'\n" "${_prtcl}"
            echo '...exit'
            exit 1
            ;;
    esac

    if ${_is_curl}; then
        if [ ! -z "${_oname}" ]; then
            curl ${_curl_opt[@]} -o "${_oname}" "${_url}"
        else
            curl ${_curl_opt[@]} --remote-name "${_url}"
        fi
    fi

    return 0
}

# Decompress an archive.
function decomp_arch() {
    # $1: PATH of the target archive

    local -r _fname=${1}

    if [ -z "${_fname}" ]; then
        echo 'decomp_arch: ${1} should be specified!'
        echo '...exit'
        exit 1
    fi

    local -r _ext='.'"${_fname##*.}"
    local -r _fname_noext="${_fname%${_ext}}"
    local _is_ok=false

    case "${_ext}" in
        .gz )
            if [ "${_fname_noext##*.}" = 'tar' ]; then
                tar xzf "${_fname}" && _is_ok=true
            fi
            ;;
        .bz2 )
            if [ "${_fname_noext##*.}" = 'tar' ]; then
                tar xjf "${_fname}" && _is_ok=true
            fi
            ;;
        .lz | .lzma )
            if [ "${_fname_noext##*.}" = 'tar' ]; then
                tar xf "${_fname}" && _is_ok=true
            fi
            ;;
        .xz )
            if [ "${_fname_noext##*.}" = 'tar' ]; then
                tar Jxf "${_fname}" && _is_ok=true
            fi
            ;;
        * )
            printf "decomp_arch, Unknown Format: '%s'\n" "${_fname}"
            echo '...exit'
            exit 1
            ;;
    esac

    if ${_is_ok}; then
        return 0
    else
        printf "decomp_arch, '%s' is not a tar archive\n" "${_fname}"
        echo '...exit'
        exit 1
    fi
}

# Check wheter cpath exists.
function check_cpath() {
    if type -P cpath > /dev/null 2>&1; then
        return 0
    else
        echo 'cpath cannot be found in PATH'
        echo '...exit'
        exit 1
    fi
}

function apply_patch() {
    local -r _patch_file="${1}"
    local _src_dir="${2}"
    local -r _log_file="${3}"
    local _new_log="${4}"

    if [ -z "${_patch_file}" ]; then
        echo 'apply_patch: ${1} should be specified!'
        echo '...exit'
        exit 1
    elif [ ! -f "${_patch_file}" ]; then
        echo 'apply_patch: ${1} does not exist or is not a regular file!'
        echo '...exit'
        exit 2
    fi

    local -r _patch_name="${_patch_file##*/}"
    local -r _prefix_num="${_patch_name%%-*.patch}"
    if [ -z "${_prefix_num}" ]; then
        echo 'apply_patch: malformed patch name!'
        echo '...exit'
        exit 3
    fi

    if [ -z "${_src_dir}" ]; then
        echo 'apply_patch: ${2} should be specified!'
        echo '...exit'
        exit 4
    elif [ ! -d "${_src_dir}" ]; then
        echo 'apply_patch: ${2} does not exist or is not a directory!'
        echo '...exit'
        exit 5
    fi

    if [ "${_src_dir:${#_src_dir}}" != '/' ]; then
        _src_dir="${_src_dir}"'/'
    fi

    if [ -z "${_log_file}" ]; then
        echo 'apply_patch: ${3} should be specified!'
        echo '...exit'
        exit 6
    elif [ ! -f "${_log_file}" -a "${_log_file}" != '/dev/null' ]; then
        touch "${_log_file}"
    fi

    if [ -z "${_new_log}" ]; then
        _new_log=false
    fi
    local _rd
    if ${_new_log}; then
        _rd='>'
    else
        _rd='>>'
    fi

    if [ ! -f "${_src_dir}"patched_${_prefix_num}.marker ]; then
        pushd "${_src_dir}" > /dev/null
        eval patch -p1 -i "${_patch_file}" $_rd "${_log_file}" 2>&1 || exit -1
        touch "${_src_dir}"patched_${_prefix_num}.marker
        popd > /dev/null
    fi

    return 0
}
