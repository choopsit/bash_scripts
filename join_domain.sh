#!/usr/bin/env bash

# Description: LDAP client with sssd authentification (also works with ubuntu)
# Author: Choops <choopsbd@gmail.com>

error="\e[31mERROR\e[0m:"
done="\e[32mDONE\e[0m:"

set -e
trap 'echo -e "${error} \"\e[33m${BASH_COMMAND}\e[0m\" (line ${LINENO}) failed with exit code $?"' ERR

usage(){
    echo -e "USAGE:\n  './$(basename "$0") [OPTIONS]' as root or using 'sudo'"
    echo -e "\n  OPTIONS:"
    echo "    -h|--help:                      Print this help"
    echo "    -d|--domain [<ADMIN>@]<DOMAIN>: Define domain (with admin login. Default admin: 'administrator')"
    exit "${err}"
}

fix_dns(){
    nodns_conf="/etc/NetworkManager/conf.d/no-dns.conf"

    if (dpkg -l | grep -q network-manager) && { [[ ! ${nodns_conf} ]] || ! (grep -qs "dns=none" "${nodns_conf}"); }; then
        echo -e "[main]\ndns=none" > "${nodns_conf}"
    fi

    if [[ -L /etc/resolv.conf ]]; then
        mv /etc/resolv.conf /etc/resolv.conf.o
    fi

    if ! (grep -qs "${domain}" /etc/resolv.conf); then
        echo -e "domain ${domain}\nsearch ${domain}\nnameserver ${dns_ip}" > /etc/resolv.conf
    fi

    if (dpkg -l | grep -q network-manager); then
        systemctl restart NetworkManager
    fi
}

configure_ntp(){
    (grep -qs "${ad_server}" /etc/systemd/timesyncd.conf) || \
        sed -e "s/#NTP=/NTP=${ad_server}/" -i /etc/systemd/timesyncd.conf

    timedatectl set-ntp true
    systemctl restart systemd-timesyncd.service
    timedatectl --adjust-system-clock
}

configure_samba(){
    sed -e "s/workgroup = WORKGROUP/workgroup = ${workgroup}\n    client signing = yes\n    client use spnego = yes\n    kerberos method = secrets and keytab\n    realm = ${domain}\n    security = ads/" -i /etc/samba/smb.conf
}

configure_autocreate_user_home(){
    (grep -qs "skel" /etc/pam.d/common-session) || \
        echo "session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
}

join_domain(){
    kinit "${adminlogin}"
    net ads join -k "${domain}"
}

configure_sssd(){
    sed -e "s|\${realm}|${realm}|g" \
        -e "s|\$(hostname -s).\${domain}|$(hostname -s).${domain}|" \
        -e "s|\${ad_server}|${ad_server}|" \
        "${confpath}"/sssd/sssd.conf > /etc/sssd/sssd.conf

    chmod 600 /etc/sssd/sssd.conf

    systemctl restart sssd
}

err=0

scriptpath="$(dirname "$(realpath "$0")")"
resourcespath="$(dirname "${scriptpath}")"/resources
confpath="${resourcespath}"/templates

[[ $(whoami) != root ]] && echo "${error} Need higher privileges." && err=1 && usage

[[ $# -gt 2 ]] && echo -e "${error} Too many arguments" && err=1 && usage

adminlogin=administrator
if [[ $# -gt 0 ]]; then
    case $1 in
    -h|--help)   usage ;;
    -d|--domain) 
        if [[ $# -gt 1 ]]; then
            if [[ $2 =~ [@] ]]; then
                adm=${2%@*}
                dom=${2##*@}
                if [[ ${adm} =~ ^[a-z][-a-z0-9]*\$ ]]; then
                    adminlogin="${adm}"
                else
                    echo -e "${error} '${adm}' is not a valid username" && err=1 && usage
                fi
                if [[ ${dom} =~ ^[a-z][-a-z0-9.]*[a-z]$ ]] && [[ ${dom} =~ [.] ]]; then
                    domain=${dom}
                else
                    echo -e "${error} '${dom}' is not a valid domain name" && err=1 && usage
                fi
            elif [[ $2 =~ ^[a-z][-a-z0-9.]*[a-z]$ ]] && [[ $2 =~ [.] ]]; then
                domain=$2
            else
                echo -e "${error} '$2' is not a valid domain name" && err=1 && usage
            fi
        else
            echo -e "${error} No domain set" && err=1 && usage
        fi ;;
    *)
        echo -e "${error} Bad argument" && err=1 && usage
esac

apt-get install -y \
    dnsutils sssd sssd-tools libnss-sss libpam-sss krb5-user adcli samba-common-bin

realm="${domain^^}"
dns_ip=$(dig | awk -F"(" '/SERVER:/{print $2}' | sed 's/.$//')
ad_server=$(dig "${domain}" | awk '/\sNS/{print $5}')
workgroup=$(cut -d'.' -f 1 <<< "${realm}")

fix_dns

configure_ntp
configure_samba
configure_autocreate_user_home
join_domain
configure_sssd

echo -e "${done} '$(hostname -s)' joined '${realm}'. You need to reboot to make it effective."
read -p "Reboot now ? [Y/n] " -rn1 reboot
[[ ! "${reboot}" ]] || echo
[[ ! ${reboot} =~ [nN] ]] && reboot
