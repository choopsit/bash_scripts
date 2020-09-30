#!/usr/bin/env bash

description="Create a bootable USB key to install Debian"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"
cw="\e[33m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"
warning="${cw}Warning${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo -e "${warning} You must have a FAT32 formated USB key mounted to use this script"
    echo
}

detect_fatdevice(){
    mapfile -t fat_device < <(df -hT | awk '/vfat/{print $1}')
    [[ ! ${fat_device[*]} ]] && echo -e "${error} Could not find suitable device"  &&
        usage && exit 1

    if [[ ${#fat_device[@]} -gt 1 ]]; then
        echo -e "${ci}${#fat_device[@]} devices can be used${c0}:"
        for suitable_device in "${fat_device[@]}"; do
            echo -e "        - '${ci}${suitable_device}${c0}'"
        done
        for suitable_device in "${fat_device[@]}"; do
            read -p "Do you want to use ${suitable_device} (mounted on $(mount | awk '/'"${suitable_device}"'/{print $3}') ? [Y/n] " -rn1 ok_device
            [[ ${ok_device} ]] && echo
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
        1) iso_url="${baseurl}/release/current/amd64/iso-cd/debian-${last_stable}-amd64-netinst.iso" ;;
        2) iso_url="${baseurl}/archive/latest-oldstable/amd64/iso-cd/debian-${last_oldstable}-amd64-netinst.iso" ;;
        3) iso_url="${baseurl}/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso" ;;
        *) echo -e "${error} Invalid choice '${vchoice}'" && choose_version ;;
    esac
}

create_usbkey(){
    myiso=/tmp/mydebian.iso
    rm -f "${myiso}"
    wget "${iso_url}" -O "${myiso}"

    umount "${mydevice}"
    if dd bs=4M if="${myiso}" of="${mydevice::-1}" conv=fdatasync; then
        echo -e "${done} Debian ${versions[$((vchoice-1))]} bootable USB key ready to use"
    fi
}

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -*)
            echo -e "${error} Unknown option '$1'" && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && exit 1

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && usage && exit 1

stable_codename=buster
last_stable=10.6.0
oldstable_codename=stretch
last_oldstable=9.13.0
testing_codename=bullseye

detect_fatdevice
choose_version
create_usbkey
