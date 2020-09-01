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

badarg_exit(){
    badarg="$1"
    echo -e "${error} Bad argument '${badarg}'" && usage && exit 1
}

test_target(){
    mytarget="$1"
    if [[ ! -e /dev/"${mytarget}" ]]; then
        echo -e "${error} Invalid target '${mytarget}'" && exit 1
    fi
    target="${mytarget}"
}

test_codename(){
    mycodename="$1"
    oklist=("buster" "sid")
    for cnok in ${oklist[@]}; do
        [[ ${mycodename} = ${cnok} ]] && codename="${mycodename}" && break
    done
    if [[ ! ${codename} ]]; then
        echo -e "${error} Invalid codename '${mycodename}'" && exit 1
    fi
}

test_username(){
    myusername="$1"
    [[ ${#myusername} -lt 2 ]] &&
        echo -e "${error} '$myusername' is too short (at least 2 characters)"

    [[ ${#myusername} -eq 2 ]] && [[ ${myusername} =~ ^[a-z][a-z0-9]$ ]] &&
        username="${myusername}"

    [[ ${#myusername} -gt 2 ]] && [[ ${myusername} =~ ^[a-z][a-z0-9-]+[a-z0-9]$ ]] &&
        username="${myusername}"

    if [[ ! ${username} ]]; then
        echo -e "${error} Invalid username '${myusername}'" && exit 1
    fi  
}

args=("$@")

[[ $# -lt 1 ]] && echo -e "${error} Need at least one argument" && usage && exit 1

for i in $(seq $#); do
    opt="${args[$((i-1))]}"
    if [[ ${opt} = -* ]]; then
        [[ ! ${opt} =~ ^-(h|-help|c|-codename|u|-username|K)$ ]] && badarg_exit "${opt}"
        arg="${args[$i]}"
    fi
    [[ ${opt} =~ ^-(h|-help)$ ]] && usage && exit 0
    [[ ${opt} =~ ^-(c|-codename)$ ]] && test_codename "${arg}"
    [[ ${opt} =~ ^-(u|-username)$ ]] && test_username "${arg}"
    [[ ${opt} = -K ]] && krust=true
done

[[ ${args[-1]} ]] && test_target "${args[-1]}"

[[ ${krust} ]] && echo -e "${cw}Krusty!!!${c0}"
[[ ${codename} ]] && echo -e "${ci}Codename${c0}: ${codename}"
[[ ${username} ]] && echo -e "${ci}Username${c0}: ${username}"
[[ ${target} ]] && echo -e "${ci}Target${c0}: ${target}"
