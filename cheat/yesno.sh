#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"

error="${ce}Error${c0}:"

read -p "Y(es) or N(o)? " -rn1 yesno
[[ ! ${yesno} ]] || echo
case ${yesno} in
    y|Y) echo "Yes" ;;
    n|N) echo "No" ;;
    *)   echo -e "${error} Invalid choice" && exit 1 ;;
esac
