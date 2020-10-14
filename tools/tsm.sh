#!/usr/bin/env bash

description="Make 'transmission-cli' manipulations simplified"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cok="\e[32m"
cw="\e[33m"
ci="\e[36m"

error="${ce}E${c0}:"
done="${cok}OK${c0}:"
warning="${cw}W${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help:    Print ths help"
    echo "  -a <TORRENT>: Add <TORRENT> to queue"
    echo "  -A:           Add all torrents from '~/Downloads/' to queue"
    echo "  -d <ID>:      Remove torrent with queue-id <ID> and delete downloaded content"
    echo "  -D:           Remove all torrents from queue and delete downloaded content"
    echo "  -r:           Restart daemon"
    echo "  -s:           Daemon status"
    echo "  -t:           Test port"
    echo "if no option:   Show queue evolution refreshing every 2s (press a key to quit)"
    echo
}

too_many_args(){
    echo -e "${error} Too many arguments" && usage && exit 1
}

add_one(){
    [[ ! $1 ]] && echo -e "${error} No torrent file given" && usage && exit 1

    if [[ $1 = *".torrent" ]] && [[ -f "$1" ]]; then
        tname="$(basename "$1")"
        echo -e "${ci}Adding${c0} ${tname%.*}"
        transmission-remote -a "$1" && rm "$1"
    else
        echo -e "${error} '$1' is not a torrent file" && exit 1
    fi
}

add_all(){
    for torrent in ~/Downloads/*.torrent; do
        if [[ -f "${torrent}" ]]; then
            tname="$(basename "${torrent}")"
            echo -e "${ci}Adding${c0} ${tname%.*}"
            transmission-remote -a "${torrent}" && rm "${torrent}"
        fi
    done
}

rm_one(){
    [[ ! $1 ]] && echo -e "${error} No torrent ID given" && usage && exit 1

    tname="$(transmission-remote -t "$1" -i | awk '/Name:/ {print $2}')"
    if [[ ${tname} ]]; then
        echo -e "${ci}Removing${c0} ${tname}"
        transmission-remote -t "$1" -rad
    else
        echo -e "${error} No torrent with ID '$1'" && exit 1
    fi
}

rm_all(){
    echo -e "${warning} This will remove all your currently active torrents"
    read -p "Are you sure [Y/n] ? " -rn1 killemall
    [[ ! ${killemall} ]] || echo
    [[ ${killemall} =~ [nN] ]] && exit 0

    mapfile -t tidlist < <(transmission-remote -l | awk '{print $1}')
    for tid in "${tidlist[@]}"; do
        if [[ ${tid} =~ ^[0-9]+$ ]]; then
            tname="$(transmission-remote -t "${tid}" -i | awk '/Name:/ {print $2}')"
            echo -e "${ci}Removing${c0} ${tname}"
            #transmission-remote -t "${tid}" -rad
        fi
    done
}

restart_daemon(){
    echo -e "${ci}Restarting daemon...${c0}"
    sudo systemctl restart transmission-daemon && echo -e "${done} 'transmission-daemon' restarted"
}

test_port(){
    port=$(awk '/"peer-port":/ {print $2}' ~/.config/transmission-daemon/settings.json)
    port="${port/,/}"
    echo -e "${ci}Testing port${c0} ${port}"
    transmission-remote -pt
}

show_queue(){
    watch transmission-remote -l &
    read -rn 1
    kill $!
    read -t 0.1 -rn 1000000
}

if [[ $1 ]]; then
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -a)
            [[ $3 ]] && too_many_args
            add_one "$2" ;;
        -A)
            [[ $2 ]] && too_many_args
            add_all ;;
        -d)
            [[ $3 ]] && too_many_args
            rm_one "$2"
            read -p "restart daemon (reorder IDs from 1) [y/N] ? " -rn1 restartd
            [[ ! ${restartd} ]] || echo
            [[ ${restartd} =~ [yY] ]] && restart_daemon ;;

        -D)
            [[ $2 ]] && too_many_args
            rm_all && restart_daemon ;;
        -r)
            [[ $2 ]] && too_many_args
            restart_daemon ;;
        -s)
            [[ $2 ]] && too_many_args
            echo -e "${ci}Daemon status${c0}" && systemctl status transmission-daemon ;;
        -t)
            [[ $2 ]] && too_many_args
            test_port ;;
        *)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
    esac
else
    show_queue
fi
