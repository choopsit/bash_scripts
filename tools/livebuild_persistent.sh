#!/usr/bin/env bash

description="Build a Debian live persistent USB key"
author="Choops <choopsbd@gmail.com>"

# Doc: https://arpinux.developpez.com/construire-un-live-debian/

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
cw="\e[33m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

set -e

#exec 5> "${scriptpath}/$(date "+%y%m%d-%H")"_DEBUG.log
#BASH_XTRACEFD="5"
#PS4='$LINENO: '
#set -xv

usage(){
    echo -e "${ci}${description}${c0}\n${ci}Usage${c0}:"
    echo "  './$(basename "$0") [OPTIONS] <TARGET>' as root or using 'sudo'"
    echo -e "  ${cw}TARGET${c0}: targeted device (ex: 'sdb')"
    echo -e "${ci}Options${c0}"
    echo "  -h,--help:        Print this help"
    echo "  -c,--codename <CODENAME>: Define Debian version [default: 'sid']"
    echo "  -u,--username <USERNAME>: Define live session username [default: 'liveuser']"
    echo "  -H,--hostname <HOSTNAME>: Define live support hostname [default: 'sid-custom']"
    echo
}

badarg_exit(){
    echo -e "${error} Bad argument" && usage && exit 1
}

test_target(){
    mytarget="$1"
    [[ ! ${mytarget} ]] && echo -e "${error} No target given" && exit 1
    [[ ! -e /dev/"${mytarget}" ]] && echo -e "${error} '${mytarget}' is not available" && exit 1
    [[ ${mytarget} != sd* ]] && echo -e "${error} '${mytarget}' is not a valid drive name" && exit 1
    grep -qs "^/dev/${mytarget}" /proc/mounts && echo -e "${error} '${mytarget}' is mounted" && exit 1
    target="${mytarget}"
}

test_codename(){
    mycodename="$1"
    for mycodenameok in "${codenameok[@]}"; do
        [[ ${mycodename} = ${mycodenameok} ]] && codename="${mycodename}" && break
    done
    if [[ ! ${codename} ]]; then
        echo -e "${error} '${mycodename}' is not a valid codename" && exit 1
    fi
}

test_username(){
    myusername="$1"
    [[ ${myusername} =~ ^[a-z]+[a-z0-9-]+[a-z0-9]$ ]] && username="${myusername}"
    if [[ ! ${username} ]]; then
        echo -e "${error} '${myusername}' is not a valid username" && exit 1
    fi
}

test_hostname(){
    hn="$1"
    [[ ${hn} =~ ^[a-z0-9]+[a-z0-9-]+[a-z0-9]$ ]] && hostname="${hn}"
    [[ ${#hn} -le 2 ]] && [[ ${hn} =~ ^[a-z0-9]+$ ]] && hostname="${hn}"
    if [[ ! ${hostname} ]]; then
        echo -e "${error} '${hn}' is not a valid hostname" && exit 1
    fi
}

confirm_conf(){
    [[ ${codename} ]] || codename=sid
    [[ ${username} ]] || username=liveuser
    [[ ${hostname} ]] || hostname=${codename}-custom

    echo -e "${ci}Codename${c0}: ${codename}"
    echo -e "${ci}Username${c0}: ${username}"
    echo -e "${ci}Hostname${c0}: ${hostname}"
    echo -e "${ci}Target${c0}:   ${target}"
    read -p "Go [y/N] ? " -rn1 okgo
    [[ ${okgo} ]] && echo
    [[ ${okgo} =~ [yY] ]] || exit 0
}

prerequisites(){
    for pkg in isolinux live-build live-manual live-tools; do
        dpkg -l | grep -q "${pkg}" || pkglist+=("${pkg}")
    done
    if [[ ${#pkglist[@]} -gt 0 ]]; then
        apt install -yy "${pkglist[@]}"
    fi
}

build_iso(){
    echo -e "${cw}Grab a tea. It will take some time...${c0}" && sleep 1
    echo -e "${ci}Preparing build...${c0}"

    workfolder="${scriptpath}/_${codename}_livebuild_$(date "+%y%m%d-%H")"
    [[ -d "${workfolder}" ]] && rm -rf "${workfolder}"
    mkdir -p "${workfolder}"
    cp -r /usr/share/doc/live-build/examples/auto "${workfolder}"/
    cp -r "${scriptpath}"/_livebuild/auto "${workfolder}"/
    cp -r "${scriptpath}"/_livebuild/config "${workfolder}"/
    sed "s/sid/${codename}/; s/liveuser/${username}/g; s/${codename}-custom/${hostname}/" \
        -i "${workfolder}"/auto/config

    cd "${workfolder}" || exit 1
    lb config

    echo -e "${ci}Building iso image...${c0}"
    lb build

    myiso="${scriptpath}/$(date "+%y%m%d")_${codename}_amd64.iso"
    mv "${workfolder}"/*.iso "${myiso}"
    mylog="${scriptpath}/$(date "+%y%m%d-%H")_${codename}_build.log"
    mv "${workfolder}"/build.log "${mylog}"
    chown "${myuser}":"${mygroup}" {"${myiso}","${mylog}"}
    chown -R "${myuser}":"${mygroup}" "${scriptpath}"/*

    lb clean --purge

    echo -e "${done} iso image built: '${myiso}'"
    #rm -rf "${workfolder}"
}

create_persistent_usbkey(){
    echo -e "${ci}Putting iso image on target...${c0}"
    dd if="${myiso}" of=/dev/"${target}"

    echo -e "${ci}Adding persistent part...${c0}"
    wipefs "/dev/${target}"
    fdisk "/dev/${target}" <<<$'n\np\n\n\n\nw'
    sync
    mkfs.ext4 -FL persistence "/dev/${target}3"
    partprobe "/dev/${target}"
    mount "/dev/${target}3" /mnt && echo "/ union" >/mnt/persistence.conf
    sync
    umount /mnt

    echo -e "${done} USB key is ready"
}

scriptpath="$(dirname "$(realpath "$0")")"
myuser="$(stat -c '%U' "${scriptpath}")"
mygroup="$(stat -c '%G' "${scriptpath}")"

codenameok=("buster" "bullseye" "sid")

args=("$@")

[[ $# -lt 1 ]] && echo -e "${error} Need at least one argument" && usage && exit 1

for i in $(seq $#); do
    opt="${args[$((i-1))]}"
    if [[ ${opt} = -* ]]; then
        [[ ! ${opt} =~ ^-(h|-help|c|-codename|u|-username|H|-hostname)$ ]] &&
            badarg_exit "${opt}"

        arg="${args[$i]}"
    fi
    [[ ${opt} =~ ^-(h|-help)$ ]] && usage && exit 0
    [[ ${opt} =~ ^-(c|-codename)$ ]] && test_codename "${arg}"
    [[ ${opt} =~ ^-(u|-username)$ ]] && test_username "${arg}"
    [[ ${opt} =~ ^-(H|-hostname)$ ]] && test_hostname "${arg}"
done

[[ ${args[-1]} ]] && test_target "${args[-1]}"

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && exit 1

test_target "${args[-1]}"

confirm_conf
prerequisites
build_iso
create_persistent_usbkey
