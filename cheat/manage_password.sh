#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

usage(){
    echo -e "${ci}Usage${c0}:\n  './$(basename "$0") [OPITONS]' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "    -h|--help:         Print this help"
    echo "    -u <USERNAME>:     Set username"
    echo "    -o <OLD_PASSWORD>: Give old password"
    echo "    -n <NEW_PASSWORD>: Set new password"
    echo
}

set_username(){
    read -p "Username: " -r myuser
    [[ ! ${myuser} ]] && echo -e "${error} No username given." && exit 1
    if [[ ! ${myuser} =~ ^[-a-zA-Z0-9]+$ ]]; then
        echo -e "${error} '${myuser}' is not a valid username" && set_username
    fi
}

set_password(){
    read -p "New password: " -sr password && echo
    if [[ ${#password} -lt 8 ]] || [[ ! ${password} =~ [A-Z] ]] || [[ ! ${password} =~ [0-9] ]]; then
        echo -e "${error} This password is too weak. It must count at least 8 characters and contain at least one uppercase letter and one number.\nTry again..."
        set_password
    else
        read -p "Re-enter new password: " -sr password_check && echo
        if [[ ! "${password_check}" = "${password}" ]]; then
            echo -e "${error} Not the same password.\nTry again..." && set_password
        fi
    fi
}

myuser=""
oldpassword=""
password=""

if [[ $# -gt 0 ]]; then
    arg=($@)
    for i in $(seq 0 $(($#-1))); do
        case ${arg[$i]} in
            -h|--help)
                usage ;;
            -u)
                if [[ ${arg[$((i+1))]} ]] && [[ ! ${arg[$((i+1))]} =~ ^-[huon]$ ]]; then
                    myuser=${arg[$((i+1))]}
                else
                    echo -e "${error} No username given" && err=1 && usage
                fi
                ;;
            -o)
                if [[ ${arg[$((i+1))]} ]] && [[ ! ${arg[$((i+1))]} =~ ^-[huon]$ ]]; then
                    oldpassword=${arg[$((i+1))]}
                else
                    echo -e "${error} No old password given" && err=1 && usage
                fi
                ;;
            -n)
                if [[ ${arg[$((i+1))]} ]] && [[ ! ${arg[$((i+1))]} =~ ^-[huon]$ ]]; then
                    password=${arg[$((i+1))]}
                else
                    echo -e "${error} No new password given" && err=1 && usage
                fi
                ;;
            *)
                echo -e "${error} Bad argument" ;;
        esac
    done
fi

[[ ${myuser} ]] || set_username
[[ ! ${myuser} =~ ^[-a-zA-Z0-9]+$ ]] && echo -e "${error} '${myuser}' is not a valid username" && exit 1
if ! (getent passwd | grep -q ^"${myuser}:x"); then
    echo -e "${error} Unknown username '${myuser}'" && exit 1
fi
[[ ${oldpassword} ]] || { read -p "Old password: " -sr oldpassword && echo ; }
[[ ${password} ]] || set_password

echo -e "${ci}User${c0}:         ${myuser}"
echo -e "${ci}Old password${c0}: ${oldpassword}"
echo -e "${ci}Password${c0}:     ${password}"
