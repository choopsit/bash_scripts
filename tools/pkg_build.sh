#!/usr/bin/env bash

description="Build a debian package"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  './$(basename "$0") <OPTIONS>' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "    -h,--help:                 Print this help"
    echo "    -s,--source <BUILDFOLDER>: Define source folder to build"
    echo
}

test_pkgsource(){
    [[ ! $1 ]] && echo -e "${error} No source folder given" && usage && exit 1
    if [[ ! -f "$1"/DEBIAN/control ]]; then
        echo -e "${error} Invalid debian package source folder '$1'"
        usage && exit 1
    fi
    pkgsource="$1"
}

build_deb_package(){
    myuser=$(stat -c '%U' "$1")
    mygroup=$(stat -c '%G' "$1")

    chown -R root:root "$1"
    dpkg-deb --build "$1"
    chown -R "${myuser}:${mygroup}" "$1"*

    destfolder="$(dirname "$(realpath "$1")")"
    echo -e "${done} '$(basename "$1").deb' generated in '${destfolder}'."
}

[[ $# -lt 1 ]] && echo -e "${error} Argument required" && usage && exit 0

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -s|--source)
            test_pkgsource "$2" && shift ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && usage && exit 1

build_deb_package "${pkgsource}"
