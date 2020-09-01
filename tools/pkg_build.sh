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
    echo -e "${ci}${description}${c0}\n${ci}Usage${c0}:"
    echo "  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "    -h|--help:                 Print this help"
    echo "    -s|--source <BUILDFOLDER>: Define source folder to build"
    echo
}

badarg_exit(){
    badarg="$1"
    echo -e "${error} Bad argument '${badarg}'" && usage && exit 1
}

test_pkgsource(){
    mypkgsource="$1"
    [[ ! ${mypkgsource} ]] && echo -e "${error} No source folder given" && usage && exit 1
    if [[ ! -f "${mypkgsource}"/DEBIAN/control ]]; then
        echo -e "${error} Invalid debian package source folder '${mypkgsource}'"
        usage && exit 1
    fi
    pkgsource="${mypkgsource}"
}

build_deb_package(){
    buildfolder="$1"
    myuser=$(stat -c '%U' "${buildfolder}")
    mygroup=$(stat -c '%G' "${buildfolder}")

    chown -R root:root "${buildfolder}"
    dpkg-deb --build "${buildfolder}"
    chown -R "${myuser}:${mygroup}" "${buildfolder}"*

    destfolder="$(dirname "$(realpath "${buildfolder}")")"
    echo -e "${done} '$(basename "${buildfolder}").deb' generated in '${destfolder}'."
}

args=("$@")

[[ $# -gt 2 ]] && echo -e "${error} Too many arguments" && usage && exit 1
[[ $# -lt 1 ]] && echo -e "${error} '$(basename "$0")' requires arguments" && usage && exit 1

for i in $(seq $#); do
    opt="${args[$((i-1))]}"
    if [[ ${opt} = -* ]]; then
        [[ ! ${opt} =~ ^-(h|-help|s|-source)$ ]] && badarg_exit "${opt}"
        arg="${args[$i]}"
    fi
    [[ ${opt} =~ ^-(h|-help)$ ]] && usage && exit 0
    [[ ${opt} =~ ^-(s|-source)$ ]] && test_pkgsource "${arg}"
done

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && usage && exit 1

build_deb_package "${pkgsource}"
