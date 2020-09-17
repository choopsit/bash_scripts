#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
cw="\e[33m"
ci="\e[36m"

error="${ce}Error${c0}:"

usage(){
    echo -e "${ci}Usage${c0}:"
    echo "  $(basename "$0") [ -h ] [ -c CODENAME ] [ -u USERNAME ] [ -K ] <TARGET>"
    echo -e "  ${cw}TARGET${c0}: targeted device (ex: 'sdb')"
    echo "  -h,--help:              Print this help"
    echo "  -c,--codename CODENAME: Define codename ('sid' or 'buster')"
    echo "  -u,--username USERNAME: Define username (2 chars minimum, start with letter)"
    echo
}

badopt(){
    echo -e "${error} Unknown option '$1'" && usage && exit 1
}

test_target(){
    if [[ ! -e /dev/"$1" ]]; then
        echo -e "${error} Invalid target '$1'" && exit 1
    fi
    target="${mytarget}"
}

test_codename(){
    oklist=("buster" "sid")
    for cnok in ${oklist[@]}; do
        [[ ${cnok} = "$1" ]] && codename="$1"
    done
    if [[ ! ${codename} ]]; then
        echo -e "${error} Invalid codename '$1'" && exit 1
    fi
}

test_username(){
    [[ ${#1} -eq 2 ]] && [[ $1 =~ ^[a-z][a-z0-9]$ ]] && username="$1"
    [[ ${#1} -gt 2 ]] && [[ $1 =~ ^[a-z][a-z0-9-]+[a-z0-9]$ ]] && username="$1"
    if [[ ! ${username} ]]; then
        echo -e "${error} Invalid username '${myusername}'" && exit 1
    fi  
}

[[ $# -lt 1 ]] && echo -e "${error} Need at least 1 argument" && usage && exit 1

arg=("$@")
for i in $(seq 0 $((${#arg[@]}-1))); do                                          
    [[ ${arg[$i]} =~ ^-(h|-help)$ ]] && usage && exit 0                          
done

re_opts="^-(h|-help|c|-codename|u|-username|K)$"
for i in $(seq 0 $((${#arg[@]}-1))); do
    if [[ ${arg[$i]} = -* ]]; then
        [[ ! ${arg[$i]} =~ ${re_opts} ]] && badopt "${arg[$i]}"
        arg="${args[$i]}"
    fi
    [[ ${arg[$i]} =~ ^-(c|-codename)$ ]] && test_codename "${arg[$((i+1))]}"
    [[ ${arg[$i]} =~ ^-(u|-username)$ ]] && test_username "${arg[$((i+1))]}"
    [[ ${arg[$i]} = -K ]] && krust=true
done

[[ ${arg[-1]} ]] && test_target "${arg[-1]}"

[[ ${krust} ]] && echo -e "${cw}Krusty!!!${c0}"
[[ ${codename} ]] && echo -e "${ci}Codename${c0}: ${codename}"
[[ ${username} ]] && echo -e "${ci}Username${c0}: ${username}"
[[ ${target} ]] && echo -e "${ci}Target${c0}: ${target}"
