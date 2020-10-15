#!/usr/bin/env bash

description="Install configured desktop environment on Debian"
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
    echo "  ./$(basename "$0") [OPTION]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo
}

valid_dechoice(){
    if [[ ${dechoice} ]]; then
        echo
        [[ ! ${dechoice} =~ ^[1-${#deok[@]}]$ ]] &&
            echo -e "${error} Invalid choice" && exit 1

        myde="${deok[$((dechoice -1))]}"
    else
        echo "${error} No choice given"
        read -p "Install default: xfce [Y/n] ? " -rn1 okdde
        [[ ${okdde} ]] && echo
        [[ ${okdde} =~ [nN] ]] && exit 0
        myde=xfce
    fi
}

select_myde(){
    deok=("xfce" "gnome" "bspwm")

    [[ $(hostname -s) = mrchat ]] && myde=xfce

    if [[ ! ${myde} ]]; then
        echo -e "${ci}Available desktop environment configurations${c0}:"
        for i in $(seq ${#deok[@]}); do
            echo "  ${i}) ${deok[$((i-1))]}"
        done
        read -p "Your choice: " -rn1 dechoice
        valid_dechoice
    fi
}

install_myde(){
    sed 's/main$/main contrib non-free/g; /cdrom/d; /#.$/d; /./,$!d' \
        -i /etc/apt/sources.list

    webbrowser=firefox-esr
    videoplayer=gnome-mpv
    musicplayer=(rhythmbox rhythmbox-plugin-alternative-toolbar)

    if [[ $(lsb_release -sc) = sid ]]; then
        webbrowser=firefox
        videoplayer=celluloid
        musicplayer=(lollypop kid3-cli)
    fi

    { lspci | grep -qi nvidia || [[ $(hostname -s) = mrchat ]] ; } &&
        dpkg --add-architecture i386

    lspci | grep -qi nvidia && nvidiadrv=(nvidia-{driver,settings,xconfig})

    syspkgs=(
    vim ssh git curl tree htop nfs-common p7zip-full cups sudo deborphan
    "${nvidiadrv[@]}" firmware-linux printer-driver-escpr
    )
    utilspkgs=(
    terminator redshift-gtk gnome-system-monitor file-roller
    gnome-calculator simple-scan system-config-printer 
    )
    stylepkgs=({arc,papirus-icon}-theme libreoffice-{gtk3,style-sifr})
    netpkgs=("${webbrowser}" remmina)
    graphpkgs=(gthumb gimp)
    mediapkgs=("${videoplayer}" "${musicplayer[@]}" easytag)

    morepkgs=()

    if [[ $(hostname -s) = mrchat ]]; then
        { lspci | grep -q paravirtual || lspci | grep -iq virtualbox ; } ||
            morepkgs+=(virt-manager libvirt0 bridge-utils nmap kpartx)

        morepkgs+=(gnome-2048 quadrapassel supertuxkart steam)

        echo steam steam/question select "I AGREE" | debconf-set-selections
        echo steam steam/license note "" | debconf-set-selections
    fi

    if [[ $(hostname -s) =~ ^(mrchat|moignon)$ ]]; then
        morepkgs+=(nfs-kernel-server conky-all network-manager-gnome gparted)
        #morepkgs+=(docker-compose)
        morepkgs+=(blender imagemagick)
        morepkgs+=(audacity kodi kazam pitivi)
        morepkgs+=(transmission-daemon)
    fi

    case ${myde} in
        xfce)
            depkgs=(
            task-xfce-desktop task-desktop slick-greeter synaptic gvfs-backends
            xfce4-{clipman,appmenu,whiskermenu,pulseaudio,weather,xkb}-plugin
            xfce4-{appfinder,screenshooter,power-manager} catfish plank
            )
            officepkgs=(evince)
            uselesspkgs=(
            needrestart xfce4-{taskmanager,terminal} xarchiver xfburn xsane atril 
            exfalso quodlibet hv3 parole ristretto libreoffice-base
            )
            ;;
        gnome)
            depkgs=(task-gnome-desktop task-desktop)
            officepkgs=()
            uselesspkgs=()
            ;;
        bspwm)
            depkgs=(bspwm)
            officepkgs=(libreoffice-{calc,writer} evince)
            uselesspkgs=()
            ;;
    esac

    mypkgs=()
    mypkgs+=("${syspkgs[@]}" "${depkgs[@]}" "${utilspkgs[@]}" "${stylepkgs[@]}")
    mypkgs+=("${netpkgs[@]}" "${graphpkgs[@]}" "${mediapkgs[@]}" "${officepkgs[@]}")
    mypkgs+=("${morepkgs[@]}")

    echo -e "${ci}Packages to install for ${myde}${c0}:\n${mypkgs[*]}"
    read -p "Continue [Y/n] ? " -rn1 continueinst
    [[ ${continueinst} ]] && echo
    [[ ${continueinst} =~ [nN] ]] && exit 0

    echo -e "${ci}Installing ${myde} base configuration...${c0}"
    apt update
    apt full-upgrade -yy
    apt install -yy "${mypkgs[@]}"

    dpkg -l | grep "firefox " && apt purge -yy firefox-esr

    apt purge -yy "${uselesspkgs[@]}" 

    mapfile -t residualconf < <(dpkg -l | awk '/^rc/ {print $2}')
    [[ ${#residualconf[@]} -gt 0 ]] && apt purge -yy "${residualconf[@]}"

    apt autoremove --purge -yy
    apt autoclean 2>/dev/null
    apt clean 2>/dev/null

    swapconf=/etc/sysctl.d/99-swappiness.conf
    if ! (grep -qs 'vm.swappiness=5' "${swapconf}"); then
        echo vm.swappiness=5 >>"${swapconf}"
        echo vm.vfs_cache_pressure=50 >>"${swapconf}"
        sysctl -p "${swapconf}"
        swapoff -av
        swapon -av
    fi

    sshconf=/etc/ssh/sshd_config
    grep "^PermitRootLogin yes" "${sshconf}" ||
        sed 's/^#PermitRootLogin.*/PermitRootLogin yes/' -i "${sshconf}"

    systemctl restart ssh

    lines=("[Seat:*]" "greeter-hide-users=false" "[Greeter]" "draw-user-backgrounds=true")
    for line in "${lines[@]}"; do
        if ! (grep -qs "${line}" /usr/share/lightdm/lightdm.conf.d/10_my.conf); then
            echo "${line}" >>/usr/share/lightdm/lightdm.conf.d/10_my.conf
        fi
    done

    sed -e 's/^; flat-volumes = yes/flat-volumes = no/' -i /etc/pulse/daemon.conf

    grep -qs redshift /etc/geoclue/geoclue.conf ||
        echo -e "\n[redshift]\nallowed=true\nsystem=false\nusers=" >>/etc/geoclue/geoclue.conf

    sed -e 's/^DESKTOP=.*/DESKTOP=Desktop/' \
        -e 's/^DOWNLOAD=.*/DOWNLOAD=Downloads/' \
        -e 's/^TEMPLATES=.*/TEMPLATES=Templates/' \
        -e 's/^PUBLICSHARE=.*/PUBLICSHARE=/' \
        -e 's/^DOCUMENTS=.*/DOCUMENTS=Documents/' \
        -e 's/^MUSIC=.*/MUSIC=Music/' \
        -e 's/^PICTURES=.*/PICTURES=Pictures/' \
        -e 's/VIDEOS=.*/VIDEOS=Videos/' \
        -i /etc/xdg/user-dirs.defaults

    adduser "${myuser}" sudo

    if dpkg -l | grep -q libvirt; then
        adduser "${myuser}" libvirt
        adduser "${myuser}" libvirt-qemu
    fi

    dpkg -l | grep -q docker.io && adduser "${myuser}" docker

    if dpkg -l | grep -q transmission-daemon; then
        systemctl stop transmission-daemon

        tsmdconf=/etc/systemd/system/transmission-daemon.service.d/override.conf
        mkdir -p "${tsmdconf%/*}"
        echo -e "[Service]\nUser=${myuser}" >"${tsmdconf}"

        tsmduserconf="${myhome}"/.config/transmission-daemon/settings.json
        [[ -f "${tsmduserconf}" ]] && sed 's/52413,/56413,/' -i "${tsmduserconf}"

        systemctl start transmission-daemon
    fi
}

deploy_root_config(){
    rm -rf /root/.vim{rc,info}

    cp "${srcfolder}"/root/bashrc /root/.bashrc
    for conf in vim profile; do
        [[ -e /root/."${conf}" ]] && rm -rf /root/."${conf}"
        cp -r "${srcfolder}/config/${conf}" /root/."${conf}"
    done

    mkdir -p /root/bin
    for script in "${srcfolder}"/bin/*; do
        pushd /root/bin &>/dev/null
        ln -sf "${script}" .
        popd &>/dev/null
    done

    curl -sfLo /root/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    vim +PlugInstall +qall && clear
}

deploy_user_config(){
    for folder in "${myhome}" /etc/skel; do
        rm -rf "${folder}"/{.bash{rc,_logout},.vim{rc,info}}

        case ${myde} in
            xfce)
                myconf=("${srcfolder}"/config/{autostart,bash,conky,dconf,GIMP,plank,terminator,Thunar,xfce4})
                ;;
            gnome)
                myconf=("${srcfolder}"/config/{autostart,bash,conky,dconf,gedit,GIMP,terminator})
                ;;
            bspwm)
                myconf=("${srcfolder}"/config/{autostart,bash,conky,GIMP,terminator})
                ;;
        esac

        mkdir -p "${folder}"/.config
        for conf in "${myconf[@]}"; do
            cp -r "${conf}" "${folder}"/.config/
        done

        mkdir -p "${folder}"/.config/bash
        for file in "${folder}"/.bash_{history,aliases}; do
            ext="${file##*_}"
            [[ -f "${file}" ]] && mv "${file}" "${folder}/.config/bash/${ext}"
        done
        touch "${folder}"/.config/bash/history

        for conf in vim profile; do
            [[ -e "${folder}/.${conf}" ]] && rm -rf "${folder}/.${conf}"
            cp -r "${srcfolder}/config/${conf}" "${folder}/.${conf}"
        done

        curl -sfLo "${folder}"/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

        for loc in "${srcfolder}"/local/*; do
            cp -r "${loc}" "${folder}"/.local/
        done
    done

    chown -R "${myuser}":"${mygroup}" "${myhome}"
}

deploy_scripts(){
    for script in "${srcfolder}"/bin/*; do
        pushd /usr/local/bin &>/dev/null
        if [[ $SUDO_USER ]]; then
            ln -sf "${script}" .
        else
            cp "${script}" .
        fi
        popd &>/dev/null
    done
}

mrchat_specials(){
    #iscan=imagescan-bundle-debian-10-3.62.0.x64.deb
    #wget https://download2.ebz.epson.net/imagescanv3/debian/latest1/deb/x64/${iscan}.tar.gz
    #tar -xf "${iscan}".tar.gz
    #"${iscan}"/install.sh
    #rm -rf "${iscan}"*
    #for file in /usr/lib/sane/libsane-epkowa.*; do
    #    if [[ ! -f /usr/lib/x86_64-linux-gnu/sane/"$(basename "${file}")" ]]; then
    #        cp "${file}" /usr/lib/x86_64-linux-gnu/sane/
    #    fi
    #done
    #echo -e "#chmod device EPSON group\nATTRS{manufacturer}==\"EPSON\", DRIVERS==\"usb\", SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"04b8\", ATTRS{idProduct}==\"*\", MODE=\"0777\"" > /etc/udev/rules.d/79-udev-epson.rules

    if ! grep -qs grodix /etc/fstab; then
        mkdir -p /volumes/grodix
        chown -R "${myuser}:${mygroup}" /volumes/grodix
        chmod 775 /volumes/grodix
        echo -e "# grodix\nUUID=d498cab6-0d80-4b11-9c78-c422cc8ef983   /volumes/grodix  btrfs   defaults,autodefrag 0   0" >>/etc/fstab
        mount -a
    fi

    grep -qs grodix /etc/exports ||
        echo "/volumes/grodix 192.168.42.0/24(rw,all_squash,anonuid=1000,anongid=1000,sync)" >>/etc/exports

    systemctl restart nfs-kernel-server
}

coincoin_specials(){
    echo
}

moignon_specials(){
    echo
}

kaeloo_specials(){
    echo
}

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

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

[[ $(lsb_release -si) != Debian ]] && echo -e "${error} Your OS is not Debian" && exit 1
[[ $(whoami) != root ]] && echo -e "${error} Need higher privileges" && exit 1

srcfolder="$(dirname "$(realpath "$0")")"
myuser="$(awk -F":" '/:x:1000/ {print $1}' /etc/passwd)"
myhome="$(awk -F':' '/'"${myuser}"'/{print $6}' /etc/passwd)"
mygroup="$(stat -c "%G" "${myhome}")"

select_myde
install_myde
deploy_root_config
deploy_user_config
deploy_scripts
[[ ${myde} = xfce ]] && echo -e "${ci}Installing themes...${c0}" && themesupdate

myspecials=("mrchat" "coincoin" "moignon" "kaeloo")
for myspecial in "${myspecials[@]}"; do
    [[ $(hostname -s) = "${myspecial}" ]] && "${myspecial}"_specials
done

echo -e "${done} Installation finished"
read -p "Reboot now [Y/n] ? " -rn1 reboot
[[ ${reboot} ]] && echo
[[ ! ${reboot} =~ [nN] ]] && reboot
