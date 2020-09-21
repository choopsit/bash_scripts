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
    echo "  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "    -h,--help:                 Print this help"
    echo "    -s,--source <BUILDFOLDER>: Define source folder to build"
    echo
}

badopt(){
    echo -e "${error} Unknown option '$1'" && usage && exit 1
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

[[ $# -lt 1 ]] && echo -e "${error} Need at least 1 argument" && usage && exit 1

maxarg=2
[[ $# -gt ${maxarg} ]] && echo -e "${error} Too many arguments" && usage && exit 1

arg=("$@")
for i in $(seq 0 $((${#arg[@]}-1))); do
    [[ ${arg[$i]} =~ ^-(h|-help)$ ]] && usage && exit 0
done
re_opts="^-(h|-help|s|-source)"
for i in $(seq 0 $((${#arg[@]}-1))); do
    [[ ${arg[$i]} = -* ]] && [[ ! ${arg[$i]} =~ ${re_opts} ]] && badopt "${arg[$i]}"
    [[ ${arg[$i]} =~ ^-(s|-source)$ ]] && test_pkgsource "${arg[$((i+1))]}"
done

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && usage && exit 1

build_deb_package "${pkgsource}"
