#!/usr/bin/env bash

description="Watch I/O on a disk and log results"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cw="\e[33m"
ci="\e[36m"

error="${ce}Error${c0}:"
warning="${cw}Warning${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION] [DEVICE]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help:          Print this help"
    echo "  -d,--delay [DELAY]: Define delay in seconds between measures [default: 10]"
    echo
}

test_delay(){
    [[ ! $1 =~ ^[0-9]+$ ]] && echo -e "${error} Delay must be an integer" && exit 1
    delay="$1"
}

prerequisites(){
    pkgs=("sysstat")
    groups | grep -q sudo && higher="sudo"
    if [[ $(whoami) = root ]] || [[ ${higher} ]]; then
        for pkg in "${pkgs[@]}"; do
            dpkg -l | grep -q "${pkg}" || echo -e "${ci}Installing '${pkg}'...${c0}"
            "${higher}" apt install -yy "${pkg}" &>/dev/null
        done
    else
        echo -e "${error} '${pkgs[*]}' not installed. You have to install it before '${USER}' can run this script." && exit 1
    fi
}

test_device(){
    prerequisites
    [[ ! -e /dev/"$1" ]] && echo -e "${error} Unknown device '$1'" && exit 1
    ! (iostat /dev/"$1" | grep -q "$1") && echo -e "${error} '$1' is not monitorable" && exit 1
    device="$1"
}

choose_device(){
    read -p "Device to monitor [ex: sdb] ? " -r mydevice
    if [[ ${mydevice} ]]; then
        echo && test_device "${mydevice}"
    else
        echo -e "${error} No device given" && exit 1

    fi
}

reset_logfile(){
    if [[ -f "${logfile}" ]]; then
        echo -e "${warning} A precedent logfile exists"
        read -p "Delete old logfile [Y/n] ? " -rn1 resetlog
        [[ ${resetlog} ]] && echo
        if [[ ! ${resetlog} =~ [nN] ]]; then
            rm -f "${logfile}"
        fi
    fi
}

monitor_and_log(){
    echo -e "${ci}Logging I/O stats on '/dev/${device}'...${c0}\nPress any key to stop logging"

    echo -e "\n# Log for I/O on '${device}' with ${delay}s delay" >>"${logfile}"
    echo -e "DATE\t\t\tRead (kb/s)\tWrite (kb/s)" >>"${logfile}"

    while true; do
        timestamp="$(date +"[%d/%m/%y-%T]")"
        read_kbs="$(iostat /dev/"${device}" | awk '/^'"${device}"'/ {print $3}')"
        write_kbs="$(iostat /dev/"${device}" | awk '/^'"${device}"'/ {print $4}')"
        echo -e "${timestamp}\t${read_kbs}\t\t${write_kbs}" >>"${logfile}"
        if read -rN1 -t "${delay}"; then
            echo
            break
        fi
    done
}

show_logfile(){
    read -p "Visualize log [Y/n] ? " -rn1 seelog
    [[ ${seelog} ]] && echo
    [[ ${seelog} = [nN] ]] && exit 0
    cat "${logfile}"
}

logfile=/tmp/io_report.log

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--delay)
            test_delay "$2" && shift ;;
        -h|--help)
            usage && exit 0 ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 1 ]] &&
    echo -e "${error} To many positional arguments" && usage && exit 1

[[ ${#positionals[@]} -eq 1 ]] && test_device "${positionals[0]}"

[[ ! ${device} ]] && choose_device
[[ ! ${delay} ]] && delay=10
reset_logfile
monitor_and_log
show_logfile
