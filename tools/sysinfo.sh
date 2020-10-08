#!/usr/bin/env bash

description="Fetch system informations"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
ci="\e[36m"
cu="\e[33m"

error="${ce}Error${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help:    Print this help"
    echo "  -d,--default: Use default logo"
    echo
}

define_logo(){
    palette="\e[30m#\e[31m#\e[32m#\e[33m#\e[34m#\e[35m#\e[36m#\e[37m#\e[0m"

    if [[ $(awk -F"=" '/^ID=/ {print $2}' /etc/os-release) = debian ]] &&
        [[ ! ${defaultlogo} ]]; then
            clogo="\e[31m"
            logo0="${clogo}"'    ,get$$gg.    '
            logo1="${clogo}"'  ,g$"     "$P.  '
            logo2="${clogo}"' ,$$" ,o$g. "$$: '
            logo3="${clogo}"' :$$ ,$"  "  $$  '
            logo4="${clogo}"'  $$ "$,   .$$"  '
            logo5="${clogo}"'  "$$ "9$$$P"    '
            logo6="${clogo}"'   "$b.          '
            logo7="${clogo}"'     "$b.        '
            logo8="${clogo}"'        """      '
            logo9="    ${palette}     "
        else
            clogo="\e[32m"
            logo0="${clogo}"'   ##! ##!   ##! '
            logo1="${clogo}"' ##########! ##! '
            logo2="${clogo}"' ##########! ##! '
            logo3="${clogo}"'   ##! ##!   ##! '
            logo4="${clogo}"'   ##! ##!   ##! '
            logo5="${clogo}"'   ##! ##!   ##! '
            logo6="${clogo}"' ##########!     '
            logo7="${clogo}"' ##########! ##! '
            logo8="${clogo}"'   ##! ##!   ##! '
            logo9="    ${palette}     "
    fi
}

pick_infos(){
    hn="$(hostname)"
    os="$(awk -F"=" '/^PRETTY/ {gsub(/"/, "", $2); print $2}'  /etc/os-release) $(arch)"
    krnl="$(uname -r)"
    pkgs="$(dpkg -l | grep -c ^i)"
    upt="$(uptime -p | sed 's/up //')"

    shl="$(basename "$SHELL")"
    [[ ${shl} = bash ]] && shlv="${BASH_VERSION%%(*}"

    [[ ${DESKTOP_SESSION} ]] && myde="${DESKTOP_SESSION}" && de="DE${c0}:     ${myde}\t\t\t"
    [[ ${XDG_CURRENT_DESKTOP} ]] && myde="${XDG_CURRENT_DESKTOP}" && de="DE${c0}:     ${myde}\t\t\t"
    wmpath="$(update-alternatives --list x-window-manager 2>/dev/null)"
    [[ ${wmpath} ]] && de+="${ci}WM${c0}:        ${wmpath##*/}"

    if [[ ${myde} = XFCE ]]; then
        icons="$(awk -F'"' '/IconThemeName/{print $6}' ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml)"
        gtkth="$(awk -F'"' '/"ThemeName/{print $6}' ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml)"
    fi
    if [[ ${icons} ]]; then
        [[ ${#icons} -lt 7 ]] && post="\t"
        myicons="Icons${c0}:  ${icons}${post}\t\t"
    fi
    [[ ${gtkth} ]] && mygtkth="${ci}GTK-theme${c0}: ${gtkth}"

    mapfile -t cpul < <(awk -F': ' '/model name/ {print $2}' /proc/cpuinfo)
    cpu="${cpul[0]} (${#cpul[@]} threads)"

    gpu="$(lspci | awk -F': ' '/VGA/ {print $2}')"
    ram="$(free -m | awk '/^Mem:/ {print $3 " / " $2 " MB"}')"
    swap="$(free -m | awk '/^Swap:/ {print $3 " / " $2 " MB"}')"
}

display_infos(){
    echo -e " ${logo0} ${cu}${USER}${c0}@${cu}${hn}"
    echo -e " ${logo1} ${ci}OS${c0}:     ${os}"
    echo -e " ${logo2} ${ci}Kernel${c0}: ${krnl}\t${ci}Packages${c0}:  ${pkgs}"
    echo -e " ${logo3} ${ci}Uptime${c0}: ${upt}"
    echo -e " ${logo4} ${ci}Shell${c0}:  ${shl} ${shlv}"
    echo -e " ${logo5} ${ci}${de}"
    echo -e " ${logo6} ${ci}${myicons}${mygtkth}"
    echo -e " ${logo7} ${ci}CPU${c0}:    ${cpu}"
    echo -e " ${logo8} ${ci}GPU${c0}:    ${gpu}"
    echo -e " ${logo9} ${ci}RAM${c0}:    ${ram}\t${ci}Swap${c0}:      ${swap}"
    echo
}

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -d|--default)
            defaultlogo=y ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

define_logo
pick_infos
display_infos
