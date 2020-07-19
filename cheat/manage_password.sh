#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

usage(){
    echo -e "${ci}Usage${c0}:"
    echo "  './$(basename "$0") [-h|[-u USERNAME [-o OLDPASSWORD [-n NEWPASSWORD]]]]' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "    -h|--help:             Print this help"
    echo "    -u|--user USERNAME:    Set username"
    echo "    -o|--old OLD_PASSWORD: Give old password"
    echo "    -n|--new NEW_PASSWORD: Set new password"
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
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -u|--user)
            myuser="$2"
            [[ $3 =~ ^(-o|--old)+$ ]] && oldpassword="$4"
            [[ $5 =~ ^(-n|--new)+$ ]] && password="$6" ;;
        *)
            echo -e "${error} Bad argument" && usage && exit 1 ;;
    esac

fi

[[ ${myuser} ]] || set_username
[[ ! ${myuser} =~ ^[-a-zA-Z0-9]+$ ]] && echo -e "${error} '${myuser}' is not a valid username" && exit 1
if ! (getent passwd | grep -q ^"${myuser}:x"); then
    echo -e "${error} Unknown username '${myuser}' on '$(hostname)'" && exit 1
fi
[[ ${oldpassword} ]] || { read -p "Old password: " -sr oldpassword && echo ; }
[[ ${password} ]] || set_password

echo -e "${ci}User${c0}:         ${myuser}"
echo -e "${ci}Old password${c0}: ${oldpassword}"
echo -e "${ci}Password${c0}:     ${password}"
