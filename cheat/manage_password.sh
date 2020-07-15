#!/usr/bin/env bash

# Author: Choops <choopsbd@gmail.com>

err=0

error="\e[31mERROR\e[0m:"
done="\e[32mDONE\e[0m:"
info="\e[36mINFO\e[0m:"

usage(){
    echo -e "USAGE: './$(basename "$0") [OPITONS]' as root or using 'sudo'"
    echo -e "\n  OPTIONS:"
    echo "    -h|--help:         Print this help"
    echo "    -u <USERNAME>:     Set username"
    echo "    -o <OLD_PASSWORD>: Give old password"
    echo "    -n <NEW_PASSWORD>: Set new password"
    exit "${err}"
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

echo -e "\e[36mUser:\e[0m         ${myuser}"
echo -e "\e[36mOld password:\e[0m ${oldpassword}"
echo -e "\e[36mPassword:\e[0m     ${password}"
