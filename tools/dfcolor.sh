#!/usr/bin/env bash

description="Graphical filesystems usage"
author="Choops <choopsbd@gmail.com>"

set -e

c0="\e[0m"
ce="\e[31m"
ci="\e[36m"

error="${ce}Error${c0}:"

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTIONS]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo "  -a,--all:  Show all filesystems (including temporary ones)"
    echo
}

get_terminalwidth(){
    terminalwidth="$(tput cols)"
    [[ ${terminalwidth} -ge 80 ]] && terminalwidth=80
    grlength=$((terminalwidth-6))
}

select_shownfs(){
    shownfslist=()
    if [[ ${tmpfs} ]]; then
        mapfile -t shownfslist < <(df -hT)
    else
        mapfile -t shownfslist < <(df -hT | grep -v tmpfs)
    fi
}

print_fsline(){
    fscol="\e[0m"
    usecol="\e[32m"
    usegraf=""
    freecol="\e[37m"
    freegraf=""

    [[ $1 = Filesystem* ]] && fscol="\e[36m"

    fstype=$(echo "$1" | awk '{print $2}')

    remotefs=("nfs" "smbfs" "cifs" "ncpfs" "afs" "coda" "ftpfs" "mfs" "sshfs" "fuse.sshfs" "nfs4")
    for fstyper in "${remotefs[@]}"; do
        [[ ${fstype} = "${fstyper}" ]] && fscol="\e[34m"
    done

    specialfs=("tmpfs" "devpts" "devtmpfs" "proc" "sysfs" "usbfs" "devfs" "fdescfs" "linprocfs")
    for fstypes in "${specialfs[@]}"; do
        [[ ${fstype} = "${fstypes}" ]] && fscol="\e[37m"
    done

    echo -e "${fscol}${1}${c0}"

    if [[ $1 != Filesystem* ]]; then
        fsuse=$(echo "$1" | awk '{print $6}')
        [[ ${fsuse/\%/} -ge 90 ]] && usecol="\e[33m"
        [[ ${fsuse/\%/} -ge 95 ]] && usecol="\e[31m"

        usegrafl=$((${fsuse/\%/}*grlength/100))
        for i in $(seq ${usegrafl}); do
            usegraf+="#"
        done

        freegrafl=$((grlength-usegrafl))
        for i in $(seq ${freegrafl}); do
            freegraf+="-"
        done

        echo -e "  [${usecol}${usegraf}${freecol}${freegraf}${c0}]"
    fi
}

show_fs(){
for shownfs in "${shownfslist[@]}"; do
    print_fsline "${shownfs}"
done
echo
}

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -a|--all)
            tmpfs=true ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

get_terminalwidth
select_shownfs
show_fs
