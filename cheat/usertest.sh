#!/usr/bin/env bash

# Author: Choops <choopsbd@gmail.com>

echo "current user: $USER"

if [[ $SUDO_USER ]] ;then
    echo "using sudo"
    myuser="$SUDO_USER"
else
    if [[ $(whoami) = root ]]; then
        myuser=$(awk -F':' '/:1000:/ {print $1}' /etc/passwd)
    else
        myuser="$USER"
    fi
fi

echo "myuser: ${myuser}"
