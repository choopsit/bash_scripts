#!/usr/bin/env bash

# Description: Create a bootable USB key to install Debian
# Author: Choops <choopsbd@gmail.com>

error="\e[31mERROR\e[0m:"
done="\e[32mDONE\e[0m:"
warning="\e[33mWARNING\e[0m:"
info="\e[36mINFO\e[0m:"

set -e
trap 'echo -e "${error} \"\e[33m${BASH_COMMAND}\e[0m\" (line ${LINENO}) failed with exit code $?"' ERR

usage (){
    echo -e "USAGE:\n  './$(basename "$0") [OPTION]' as root or using 'sudo'"
    echo -e "\n  OPTIONS:"
    echo "    -h|--help: Print this help"
    echo -e "\n${warning} You must have a FAT32 formated USB key mounted to use this script"
    exit "${err}"
}

detect_fatdevice(){
    mapfile -t fat_device < <(df -hT | awk '/vfat/{print $1}')
    [[ ! ${fat_device[*]} ]] && echo -e "${error} Could not find suitable device" && err=1 && usage
    if [[ ${#fat_device[@]} -gt 1 ]]; then
        echo -e "${info} You have ${#fat_device[@]} devices that could be use :"
        for suitable_device in "${fat_device[@]}"; do
            echo "        - '${suitable_device}'"
        done
        for suitable_device in "${fat_device[@]}"; do
            read -p "Do you vant to use ${suitable_device} (mounted on $(mount | awk '/'${suitable_device}'/{print $3}') ? [Y/n] " -rn1 ok_device
            [[ ! ${ok_device} ]] || echo
            [[ ! ${ok_device} =~ [nN] ]] && mydevice="${suitable_device}" && break
        done
    else
        mydevice=${fat_device[*]}
    fi
}

choose_version(){
    unset iso_url

    baseurl=https://cdimage.debian.org/cdimage
    
    versions=("${stable_codename} \e[90m(stable: ${last_stable})\e[0m" \
              "${oldstable_codename} \e[90m(oldstable: ${last_oldstable})\e[0m" \
              "${testing_codename} \e[90m(testing)\e[0m")

    echo "Debian versions you can add to your USB key:"
    for i in $(seq "${#versions[@]}"); do
        echo -e "  ${i}) ${versions[$((i-1))]}"
    done
    read -p "Your choice: " -rn1 vchoice
    [[ ! ${vchoice} ]] || echo
    case ${vchoice} in
        1) iso_url="${baseurl}"/release/current/amd64/iso-cd/debian-"${last_stable}"-amd64-netinst.iso ;;
        2) iso_url="${baseurl}"/latest-oldstable/amd64/iso-cd/debian-"${last_oldstable}"-amd64-netinst.iso ;;
        3) iso_url="${baseurl}"/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso ;;
        *) echo -e "${error} Invalid choice" && choose_version
    esac

    [[ -f /tmp/mydebian.iso ]] && rm -f /tmp/mydebian.iso
    wget "${iso_url}" -O /tmp/mydebian.iso

    umount "${mydevice}" && dd bs=4M if=/tmp/mydebian.iso of="${mydevice::-1}" conv=fdatasync \
        && echo -e "${done} Debian ${versions[$((vchoice-1))]} bootable USB key ready to use"
}

err=0

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && err=1 && usage

[[ $# -gt 1 ]] && echo -e "${error} Too many arguments" && err=1 && usage

if [[ $# -eq 1 ]]; then
    case $1 in
        -h|--help)  usage ;;
        *)          echo -e "${error} Bad argument" && err=1 && usage
    esac
fi

detect_fatdevice

stable_codename=buster
last_stable=10.3.0
oldstable_codename=stretch
last_oldstable=9.12.0
testing_codename=bullseye

choose_version
