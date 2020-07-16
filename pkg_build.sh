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
    echo -e "${ci}${description}${c0}"
    echo -e "${ci}Usage${c0}:\n  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "${ci}Optionsd${c0}:"
    echo "    -h|--help:                    Print this help"
    echo "    -s|--source <PATH_TO_FOLDER>: Define source folder to build"
    echo
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

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && usage && exit 1

[[ $# -gt 2 ]] && echo -e "${error} Too many arguments" && usage && exit 1
[[ $# -lt 1 ]] && echo -e "${error} '$(basename "$0")' requires arguments" && usage && exit 1

case $1 in
    -h|--help)
        usage ;;
    -s|--source)
        [[ ! $2 ]] && echo -e "${error} No source folder given" && usage && exit 1
        [[ ! -f $2/DEBIAN/control ]] && \
            echo -e "${error} '$2' is not a debian package source folder" && usage && exit 1

        build_deb_package "$2" ;;
    *)
        echo -e "${error} Bad argument" && err=1 && usage ;;
esac
