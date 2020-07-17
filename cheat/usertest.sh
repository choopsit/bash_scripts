#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ci="\e[36m"

echo "${ci}Current user${c0}: $USER"

if [[ $SUDO_USER ]] ;then
    echo "Using 'sudo'"
    myuser="$SUDO_USER"
else
    if [[ $(whoami) = root ]]; then
        myuser=$(awk -F':' '/:1000:/ {print $1}' /etc/passwd)
    else
        myuser="$USER"
    fi
fi

echo "${ci}Real user${c0}:    ${myuser}"
