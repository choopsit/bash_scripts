#!/usr/bin/env bash

description="Backup important files and folders from home folder and some configuration files"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cok="\e[32m"
ci="\e[36m"

error="${ce}E${c0}:"
done="${cok}OK${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION] <BACKUP_FOLDER>"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo
}

test_backupfolder(){
    [[ ! $1 ]] && echo -e "${error} No backup destination folder given" && usage && exit 1
    [[ ! $1 =~ ^/.* ]] && echo -e "${error} '$1' is not an absolute path" && usage && exit 1
    forbiddenfolders=(/ /bin /boot /dev /etc /home /initrd.img /initrd.img.old /lib /lib32 /lib64 /libx32 /media /mnt /opt /proc /root /run /srv /sys /tmp /usr /var)
    for folder in "${forbiddenfolders[@]}"; do
        if [[ $1 = "${folder}" ]] || [[ $1 = "${folder}/" ]]; then
            echo -e "${error} '$1' is not a valid backup folder" && usage && exit 1
        fi
    done
    destfolder="$1"
}

prerequisites(){
    pkgs=("rsync")
    groups | grep -q sudo && higher="sudo"
    if [[ $(whoami) = root ]] || [[ ${higher} ]]; then
        for pkg in "${pkgs[@]}"; do
            dpkg -l | grep -q "${pkg}" || echo -e "${ci}Installing '${pkg}'...${c0}"
            "${higher}" apt install -yy "${pkg}" &>/dev/null
        done
    else
        echo -e "${error} '${pkgs[*]}' not installed. You have to install it before '${USER}' can run this script." && exit 1
    fi

    "${higher}" mkdir -p "${destfolder}"
    "${higher}" chmod 777 "${destfolder}"
}

backup(){
    prerequisites

    today=$(date +"%y%m")
    bkpfolder="${destfolder}/${today}_$(hostname)"

    mkdir -p "${bkpfolder}"

    errcnt=0
    for elt2backup in "${homebackups[@]}"; do
        if [[ -e ${HOME}/${elt2backup} ]]; then
            mkdir -p "$(dirname "${bkpfolder}${HOME}/${elt2backup}")"
            rsync -Oatzulr --delete --exclude '*~' "${HOME}/${elt2backup}" "${bkpfolder}${HOME}/$(dirname "${elt2backup}")"/ || ((errcnt+=1))
        fi
    done
    [[ ${errcnt} -gt 0 ]] && errcnt="${ce}${errcnt}${c0}"
    echo -e "${done} ${USER}'s home backuped in '${bkpfolder}${HOME}' with ${errcnt} error(s)."

    errcnt=0
    for conffile in "${conffiles[@]}"; do
        if [[ -e ${conffile} ]]; then
            mkdir -p "$(dirname "${bkpfolder}${conffile}")"
            rsync -Oatzulr --delete --exclude '*~' "${conffile}" "${bkpfolder}$(dirname "${conffile}")"/ || ((errcnt+=1))
        fi
    done
    [[ ${errcnt} -gt 0 ]] && errcnt="${ce}${errcnt}${c0}"
    echo -e "${done} Config files backuped in '${bkpfolder}' with ${errcnt} error(s)."

    errcnt=0
    for more2bkp in "${morebackups[@]}"; do
        [[ -d ${more2bkp} ]] && morebkp=True
        if [[ -e ${more2bkp} ]]; then
            mkdir -p "$(dirname "${bkpfolder}${more2bkp}")"
            rsync -Oatzulr --delete --exclude '*~' "${more2bkp}" "${bkpfolder}$(dirname "${more2bkp}")"/ || ((errcnt+=1))
            morebackuped+="'${more2bkp}' and "
        fi
    done
    if [[ ${morebkp} ]]; then
        [[ ${errcnt} -gt 0 ]] && errcnt="${ce}${errcnt}${c0}"
        echo -e "${done} ${morebackuped% and*} backuped in '${bkpfolder}' with ${errcnt} error(s)."
    fi
}

homebackups=(.profile .face .kodi .mozilla .vim .config/{autostart,bash,conky,dconf,evince,gedit,GIMP,libvirt,Mousepad,openvpn,plank,picom,pitivi,remmina,terminator,transmisson-daemon,Thunar,xfce4} .local/bin .local/share/{applications,fonts,gedit,gtksourceview-3.0,gtksourceview-4,lollypop,plank,remmina,rhythmbox,xfce4} Documents Downloads Music Pictures Videos Work)
conffiles=(/etc/fstab /etc/exports /etc/ssh/sshd_config /etc/sysctl.d/99-swappiness.conf /etc/pulse/daemon.conf /etc/apt/{sources.list*,trusted*} /usr/share/lightdm/lightdm.conf.d/01_my.conf /usr/share/X11/xorg.conf.d/10-nvidia.conf)
morebackups=(/home/repo)

[[ $# -lt 1 ]] && echo -e "${error} Argument required" && usage && exit 1

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
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

test_backupfolder "${positionals[0]}"

backup
