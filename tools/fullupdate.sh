#!/usr/bin/env bash

description="Do a full upgrade conclued by system informations"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cok="\e[32m"
ci="\e[36m"

error="${ce}E${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo "  -o:        Remove local and obsolete packages"
    echo
}

system_upgrade(){
    echo -e "${ci}System upgrade${c0}:"
    sudo apt update >/dev/null 2>&1
    sudo apt full-upgrade 2>/dev/null

    mapfile -t residualconf < <(dpkg -l | awk '/^rc/ {print $2}')
    [[ "${#residualconf[@]}" -gt 0 ]] && sudo apt purge -y "${residualconf[@]}" 2>/dev/null

    [[ ${no_obs} ]] &&
        mapfile -t opkg < <(apt list ?obsolete 2>/dev/null | awk  -F'/' '/\/now/ {print $1}')

    [[ ${#opkg[@]} -gt 0 ]] && sudo apt purge -y "${opkg[@]}" 2>/dev/null

    sudo apt autoremove --purge 2>/dev/null
    sudo apt autoclean 2>/dev/null
    sudo apt clean 2>/dev/null

    rm -f ~/.xsession-*
}

themes_upgrade(){
    if which themesupdate >/dev/null; then
        echo -e "\n${ci}Themes upgrade${c0}:"
        sudo themesupdate
    fi
}

user_conf_backup(){
    if which backup >/dev/null; then
        echo -e "\n${ci}Backup${c0}:"
        [[ ${backuppath} ]] || read -p "Backup destination ? " -r backuppath
        [[ -d "${backuppath}" ]] && backup "${backuppath}"
        [[ -d "${backuppath}" ]] || echo -e "${error} '${backuppath}' is not an available folder"
    fi
}

system_informations(){
    echo -e "\n${ci}System informations${c0}:"
    date
    pyfetch
    pydf
    [[ -d ${repopath} ]] || read -p "Path to your git repos stock ? " -r repopath
    [[ ! -d ${repopath} ]] && echo -e "${error} '${repopath}' does not exist" && exit 1
    for mygit in "${repopath}"/*; do
        if [[ -d "${mygit}"/.git ]]; then
            echo -e "${ci}Git repos status${c0}:"
            statmygits "${repopath}"
            break
        fi
    done
}

repopath=~/Work/git
backuppath=/backup
[[ $(hostname -s) = mrchat ]] && backuppath=/volumes/grodix/backup

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -o)
            no_obs=true ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

system_upgrade
themes_upgrade
user_conf_backup
system_informations
