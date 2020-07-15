#!/usr/bin/env bash

# Description: Build a debian package
# Author: Choops <choopsbd@gmail.com>

error="\e[31mERROR\e[0m:"
done="\e[32mDONE\e[0m:"

set -e
trap 'echo -e "${error} \"\e[33m${BASH_COMMAND}\e[0m\" (line ${LINENO}) failed with exit code $?"' ERR

usage(){
    echo -e "USAGE:\n  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "\n  OPTIONS:"
    echo "    -h|--help:                    Print this help"
    echo "    -s|--source <PATH_TO_FOLDER>: Define source folder to build"
    exit "${err}"
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

err=0

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && err=1 && usage

[[ $# -gt 2 ]] && echo -e "${error} Too many arguments" && err=1 && usage
[[ $# -lt 1 ]] && echo -e "${error} '$(basename "$0")' requires arguments" && err=1 && usage

case $1 in
    -h|--help)
        usage ;;
    -s|--source)
        [[ ! $2 ]] && echo -e "${error} No source folder given" && err=1 && usage
        [[ ! -f $2/DEBIAN/control ]] && \
            echo -e "${error} '$2' is not a debian package source folder" && err=1 && usage
        build_deb_package "$2" ;;
    *)  echo -e "${error} Bad argument" && err=1 && usage
esac
