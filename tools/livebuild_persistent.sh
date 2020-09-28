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

codenameok=("buster" "bullseye" "sid")

#set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  './$(basename "$0") [OPTIONS] <TARGET>' as root or using 'sudo'"
    echo -e "  ${cw}TARGET${c0}: targeted device (ex: 'sdb')"
    echo -e "${ci}Options${c0}"
    echo "  -h,--help:                Print this help"
    echo "  -c,--codename <CODENAME>: Define Debian version [default: '${codenameok[0]}']"
    echo -e "    ${cw}Warning${c0}: Only '${codenameok[0]}' can build an installable support."
    echo "  -u,--username <USERNAME>: Define live session username [default: 'liveuser']"
    echo "  -H,--hostname <HOSTNAME>: Define live support hostname [default: '${codenameok[0]}-custom']"
    echo
}

test_target(){
    [[ ! $1 ]] && echo -e "${error} No target given" && exit 1
    [[ ! -e /dev/"$1" ]] && echo -e "${error} Target '$1' not available" && exit 1
    [[ $1 != sd* ]] && echo -e "${error} Invalid drive name '$1'" && exit 1
    grep -qs "^/dev/$1" /proc/mounts && echo -e "${error} '$1' mounted" && exit 1
    target="$1"
}

test_codename(){
    for cnok in "${codenameok[@]}"; do
        [[ ${cnok} = "$1" ]] && codename="$1" && break
    done
    if [[ ! ${codename} ]]; then
        echo -e "${error} Invalid codename '$1'" && exit 1
    fi
}

test_username(){
    [[ $1 =~ ^[a-z]+[a-z0-9-]+[a-z0-9]$ ]] && username="$1"
    if [[ ! $1 ]]; then
        echo -e "${error} Invalid username '$1'" && exit 1
    fi
}

test_hostname(){
    [[ $1 =~ ^[a-z0-9]+[a-z0-9-]+[a-z0-9]$ ]] && hostname="$1"
    [[ ${#1} -le 2 ]] && [[ $1 =~ ^[a-z0-9]+$ ]] && hostname="$1"
    if [[ ! ${hostname} ]]; then
        echo -e "${error} Invalid hostname '$1'" && exit 1
    fi
}

confirm_conf(){
    [[ ${codename} ]] || codename="${codenameok[0]}"
    [[ ${username} ]] || username=liveuser
    [[ ${hostname} ]] || hostname="${codename}-custom"

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

    pushd "${workfolder}" || exit 1
    lb config

    echo -e "${ci}Building iso image...${c0}"
    lb build

    myiso="${scriptpath}/$(date "+%y%m%d")_${codename}_amd64.iso"
    mv "${workfolder}"/*.iso "${myiso}"
    chown "${myuser}":"${mygroup}" "${myiso}"
    chown -R "${myuser}":"${mygroup}" "${scriptpath}"/*.iso

    lb clean --purge
    popd || exit 1

    echo -e "${done} iso image built: '${myiso}'"
}

create_persistent_usbkey(){
    echo -e "${ci}Cleaning USB key...${c0}"
    if [[ -e "/dev/${target}3" ]]; then
        for i in {3..1}; do
            wipefs "/dev/${target}${i}"
            fdisk "/dev/${target}" <<<$"d\n\n\nw"
        done
        partprobe
    fi
    echo -e "${ci}Putting iso image on target...${c0}"
    dd if="${myiso}" of=/dev/"${target}"

    echo -e "${ci}Adding persistent part...${c0}"
    wipefs "/dev/${target}"
    fdisk "/dev/${target}" <<<$'n\np\n\n\n\nw'
    partprobe
    sync
    mkfs.ext4 -FL persistence "/dev/${target}3"
    mount "/dev/${target}3" /mnt && echo "/ union" >/mnt/persistence.conf
    sync
    umount /mnt

    rm -rf "${workfolder}"

    echo -e "${done} USB key is ready"
    read -p "Keep '$(basename "${myiso}")' [y/N] ? " -rn1 keepiso
    [[ ${keepiso} ]] && echo
    [[ ! ${keepiso} =~ [yY] ]] && rm -f "${myiso}"
}

scriptpath="$(dirname "$(realpath "$0")")"
myuser="$(stat -c '%U' "${scriptpath}")"
mygroup="$(stat -c '%G' "${scriptpath}")"

[[ $# -lt 1 ]] && echo -e "${error} Argument required" && usage && exit 0

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--codename)
            test_codename "$2" && shift ;;
        -u|--username)
            test_username "$2" && shift ;;
        -H|--hostname)
            test_hostname "$2" && shift ;;
        -h|--help)
            usage && exit 0 ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -ne 1 ]] &&
    echo -e "${error} Need a unique positional argument" && usage && exit 1

test_target "${positionals[0]}"

[[ $(whoami) != root ]] && echo "${error} Need higher privileges." && usage && exit 1

confirm_conf
prerequisites
build_iso
create_persistent_usbkey
