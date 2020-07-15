#!/usr/bin/env bash

# Description: Obtain network informations (also works with ubuntu)
# Author: Choops <choopsbd@gmail.com>

error="\e[31mERROR\e[0m:"
done="\e[32mDONE\e[0m:"

set -e
trap 'echo -e "${error} \"\e[33m${BASH_COMMAND}\e[0m\" (line ${LINENO}) failed with exit code $?"' ERR

usage(){
    echo -e "USAGE:\n  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "\n  OPTIONS:"
    echo "    -h|--help: Print this help"
    exit "${err}"
}

prerequisites(){
    if ! (dpkg -l | grep -q dnsutils); then
        if [[ $(whoami) = root ]]; then
            apt-get install -qq dnsutils > /dev/null
        elif (groups | grep -q sudo); then
            sudo apt-get install -qq dnsutils > /dev/null
        else
            echo -e "${error} 'dnsutils' is not installed. You have to install it before '${USER}' can run this script." && exit 1
        fi
    fi
}

pick_naming_infos(){
    myhostname=$(hostname -s)

    fqdn=$(hostname -f)
    [[ ${fqdn} =~ [*.*] ]] && show_fqdn="\nFQDN:      ${fqdn}"
}

list_interfaces(){
    mapfile -t iface < <(ip a | awk -F":" '/<BROADCAST,MULTICAST,UP,LOWER_UP>/{print $2}' | sed -e "s/\ //")
}

pick_network_infos(){
    iface="$1"

    mtu=$(ip a sh "${iface}" | awk '/mtu/{print $5}')
    ipaddr=$(ip a sh "${iface}" | awk '/inet /{print $2}' | cut -d'/' -f1)
    macaddr=$(ip a sh "${iface}" | awk '/link\/ether/{print $2}')
    gatewayip=$(ip route | awk '/default via/{print $3}')
    dnsip=$(dig | awk -F"(" '/SERVER:/{print $2}' | sed 's/.$//')

    if [[ ${ipaddr} ]]; then
        network_results+="\n\e[36mInterface\e[0m: ${iface}"
        network_results+="\n\e[36m  - MTU\e[0m:            ${mtu}"
        network_results+="\n\e[36m  - MAC address\e[0m:    ${macaddr}"
        network_results+="\n\e[36m  - IP address\e[0m:     ${ipaddr}"
        network_results+="\n\e[36m  - Gateway\e[0m:        ${gatewayip}"
        network_results+="\n\e[36m  - DNS nameserver\e[0m: ${dnsip}"
    elif [[ $(ip a sh "${iface}") = *master* ]] && [[ ${iface} != vnet* ]]; then
        bridge=$(ip a | awk '/'${iface}'/{print $9}')
        network_results+="\n\e[36mInterface\e[0m: ${iface} [master of bridge '${bridge}']"
    fi
}

err=0

[[ $# -gt 1 ]] && echo -e "${error} Too many arguments" && err=1 && usage

if [[ $# -eq 1 ]]; then
    case $1 in
        -h|--help) usage ;;
        *)         echo -e "${error} Bad argument" && err=1 && usage
    esac
fi

prerequisites
pick_naming_infos
list_interfaces
for iface_n in "${iface[@]}"; do
    pick_network_infos "${iface_n}"
done

echo -e "\e[36mHostname\e[0m: ${myhostname}${show_fqdn}${network_results}"
