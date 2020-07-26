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

#set -e

usage(){
    echo -e "${ci}${description}${c0}"
    echo -e "${ci}Usage${c0}:"
    echo "  './$(basename "$0") <-h|-t <DEVICE> [-c <CODENAME>] [-u <USERNAME>]>'"
    echo -e "${ci}Options${c0}:"
    echo "  -h|--help:                Print this help"
    echo "  -t|--target <DEVICE>:     Define targeted device (ex: 'sdb')"
    echo "  -c|--codename <CODENAME>: Define Debian version to put on flash drive [default: 'buster']"
    echo "  -u|--user <USERNAME>:     Define username [default: 'liveuser']"
}

bad_arg_exit(){
    echo -e "${error} Bad argument" && usage && exit 1
}

target_test(){
    tgt="$1"
    [[ ! ${tgt} ]] && echo -e "${error} No device given" && exit 1
    [[ ! -e /dev/"${tgt}" ]] && echo -e "${error} '${tgt}' is not available" && exit 1
    [[ ${tgt} != sd* ]] && echo -e "${error} '${tgt}' is not a valid drive name" && exit 1
    grep -qs "^/dev/${tgt}" /proc/mounts && echo -e "${error} '${tgt}' is mounted" && exit 1
    device="${tgt}"
}

codename_test(){
    cn="$1"
    for cnok in "${codenameok[@]}"; do
        [[ ${cn} = ${cnok} ]] && codename="${cn}" && break
    done
    if [[ ! ${codename} ]]; then
        echo -e "${error} Invalid Dedian codename '${cn}'" && exit 1
    fi
}

username_test(){
    usr="$1"
    [[ ${usr} =~ ^[-a-zA-Z0-9]+$ ]] && username="${usr}"
    if [[ ! ${username} ]]; then
        echo -e "${error} Invalid username '${usr}'" && exit 1
    fi
}

prerequisites(){
    for pkg in live-build live-manual live-tools; do
        dpkg -l | grep -q "${pkg}" || apt install -yy "${pkg}"
    done
}

build_image(){
    echo -e "${ci}Preparing build...${c0}"
    workfolder="${scriptpath}/livebuild_$(date "+%y%m%d-%H")"

    [[ -e "${workfolder}" ]] && rm -rf "${workfolder}"
    mkdir -p "${workfolder}"

    cd "${workfolder}" || exit 1
    cp -r /usr/share/doc/live-build/examples/auto .
    cp -r "${scriptpath}"/_livebuild/auto .
    sed "s/sid/${codename}/; s/liveuser/${username}/" -i auto/config

    lb config

    echo -e "${ci}Build image...${c0}"
    lb clean && lb build

    myiso="${scriptpath}/my${codename}-live-amd64.iso"
    mv "${workfolder}"/live-image-amd64.hybrid.iso "${myiso}"
    chown "${myuser}":"${mygroup}" "${myiso}"

    echo -e "${done}: Image created: '${myiso}'"
}

create_usbkey(){
    echo -e "${ci}Creating USB key...${c0}"
    dd if="${myiso}" of="/dev/${device}" bs=512
    sync

    echo -e "${ci}Adding persistent part...${c0}"
    fdisk "/dev/${device}" <<<$'n\np\n\n\n\nw'
    partprobe <<<$'y'
    sync
    mkfs.ext4 -L persistence "/dev/${device}3"
    mount "/dev/${device}3" /mnt && echo "/ union" >/mnt/persistence.conf
    umount /mnt
    sync

    rm -rf "${workfolder}"

    echo -e "${done}: Persistent live-usb based on '${myiso}' ready to use"
}

codenameok=("buster" "bullseye" "sid")

[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && exit 1

case $1 in
    -h|--help)
        usage && exit 0
        ;;
    -t|--target)
        target_test "$2"
        if [[ $3 ]]; then
            case $3 in
                -c|--codename)
                    codename_test "$4"
                    if [[ $5 ]]; then
                        case $5 in
                            -u|--user) username_test "$6" ;;
                            *) bad_arg_exit ;;
                        esac
                    fi
                    ;;
                -u|--user)
                    username_test "$4"
                    if [[ $5 ]]; then
                        case $5 in
                            -c|--codename) codename_test "$6" ;;
                            *) bad_arg_exit ;;
                        esac
                    fi
                    ;;
                *)
                    bad_arg_exit
                    ;;
            esac
        fi
        ;;
    *)
        bad_arg_exit
        ;;
esac

[[ ${codename} ]] || codename="${codenameok[0]}"
[[ ${username} ]] || username=liveuser

echo -e "${ci}Codename${c0}: ${codename}"
echo -e "${ci}Username${c0}: ${username}"
echo -e "${ci}Target${c0}: /dev/${device}"
read -p "Go [Y/n] ? " -rn1 okgo
[[ ${okgo} ]] && echo
[[ ${okgo} =~ [nN] ]] && exit 0
echo -e "${cw}Grab a tea. It will take some time...${c0}" && sleep 1

scriptpath="$(dirname "$(realpath "$0")")"
myuser="$(stat -c '%U' "${scriptpath}")"
mygroup="$(stat -c '%G' "${scriptpath}")"

prerequisites
build_image
create_usbkey
