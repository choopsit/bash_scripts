#!/usr/bin/env bash

# Author: Choops <choopsbd@gmail.com>

error="\e[31mERROR\e[0m:"

read -p "Y(es) or N(o)? " -rn1 yesno
[[ ! ${yesno} ]] || echo
case ${yesno} in
    y|Y) echo "Yes" ;;
    n|N) echo "No" ;;
    *)   echo -e "${error} Invalid choice" && exit 1
esac
