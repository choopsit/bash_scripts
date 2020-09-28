#!/usr/bin/env bash

description="Obtain network informations"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  ./$(basename "$0") [OPTIONS]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo
}

prerequisites(){
    pkgs=("dnsutils")
    groups | grep -q sudo && higher="sudo"
    if [[ $(whoami) = root ]] || [[ ${higher} ]]; then
        for pkg in "${pkgs[@]}"; do
            dpkg -l | grep -q "${pkg}" || echo -e "${ci}Installing '${pkg}'...${c0}"
            "${higher}" apt install -yy "${pkg}" &>/dev/null
        done
    else
        echo -e "${error} '${pkgs[*]}' not installed. You have to install it before '${USER}' can run this script." && exit 1
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
    mtu=$(ip a sh "$1" | awk '/mtu/{print $5}')
    ipaddr=$(ip a sh "$1" | awk '/inet /{print $2}' | cut -d'/' -f1)
    macaddr=$(ip a sh "$1" | awk '/link\/ether/{print $2}')
    gatewayip=$(ip route | awk '/default via/{print $3}')
    dnsip=$(dig | awk -F"(" '/SERVER:/{print $2}' | sed 's/.$//')

    if [[ ${ipaddr} ]]; then
        network_results+="\n${ci}Interface${c0}: $1"
        network_results+="\n  - ${ci}MTU${c0}:            ${mtu}"
        network_results+="\n  - ${ci}MAC address${c0}:    ${macaddr}"
        network_results+="\n  - ${ci}IP address${c0}:     ${ipaddr}"
        network_results+="\n  - ${ci}Gateway${c0}:        ${gatewayip}"
        network_results+="\n  - ${ci}DNS nameserver${c0}: ${dnsip}"
    elif [[ $(ip a sh "$1") = *master* ]] && [[ $1 != vnet* ]]; then
        bridge=$(ip a | awk '/'"$1"'/{print $9}')
        network_results+="\n${ci}Interface${c0}: $1 [master of bridge '${bridge}']"
    fi
}

print_infos(){
    line="\n${ci}======================================${c0}"
    echo -e "${ci}Hostname${c0}: ${myhostname}${show_fqdn}${line}${network_results}"
}

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage && exit 0 ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${#positionals[@]} -gt 0 ]] &&
    echo -e "${error} Bad argument(s) '${positionals[*]}'" && usage && exit 1

prerequisites

pick_naming_infos
list_interfaces
for iface_n in "${iface[@]}"; do
    pick_network_infos "${iface_n}"
done
print_infos
