#!/usr/bin/env bash

description="Obtain network informations"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

set -e

usage(){
    echo -e "${ci}${description}${c0}"
    echo -e "${ci}Usage${c0}:\n  ./$(basename "$0") [OPTIONS]"
    echo -e "${ci}Options${c0}:"
    echo "  -h|--help: Print this help"
    echo
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
    if [[ ${fqdn} =~ [*.*] ]]; then
        show_fqdn="\n${ci}FQDN${c0}:     ${fqdn}"
    fi
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
        network_results+="\n${ci}Interface${c0}: ${iface}"
        network_results+="\n  - ${ci}MTU${c0}:            ${mtu}"
        network_results+="\n  - ${ci}MAC address${c0}:    ${macaddr}"
        network_results+="\n  - ${ci}IP address${c0}:     ${ipaddr}"
        network_results+="\n  - ${ci}Gateway${c0}:        ${gatewayip}"
        network_results+="\n  - ${ci}DNS nameserver${c0}: ${dnsip}"
    elif [[ $(ip a sh "${iface}") = *master* ]] && [[ ${iface} != vnet* ]]; then
        bridge=$(ip a | awk '/'${iface}'/{print $9}')
        network_results+="\n${ci}Interface${c0}: ${iface} [master of bridge '${bridge}']"
    fi
}

[[ $# -gt 1 ]] && echo -e "${error} Too many arguments" && usage && exit 1

if [[ $# -eq 1 ]]; then
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        *)
            echo -e "${error} Bad argument" && usage && exit 1 ;;
    esac
fi

prerequisites
pick_naming_infos
list_interfaces
for iface_n in "${iface[@]}"; do
    pick_network_infos "${iface_n}"
done

line="\n${ci}======================================${c0}"
echo -e "${ci}Hostname${c0}: ${myhostname}${show_fqdn}${line}${network_results}"