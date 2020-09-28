#!/usr/bin/env bash

description="LDAP client with sssd authentification"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cf="\e[32m"
ci="\e[36m"

error="${ce}Error${c0}:"
done="${cf}Done${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  './$(basename "$0") <OPTIONS>' as root or using 'sudo'"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help:                      Print this help"
    echo "  -d,--domain [<ADMIN>@]<DOMAIN>: Define domain (with admin login. Default admin: 'administrator')"
    echo
}

test_domain(){
    mydomain="$1"
    if [[ $1 = *@* ]]; then
        adm=${1%@*}
        dom=${1##*@}
        if [[ ${adm} =~ ^[a-z][-a-z0-9]*\$ ]]; then
            adminlogin="${adm}"
        else
            echo -e "${error} Invalid username '${adm}'" && exit 1
        fi
        if [[ ${dom} =~ ^[a-z][-a-z0-9.]*[a-z]$ ]] && [[ ${dom} =~ [.] ]]; then
            domain="${dom}"
        else
            echo -e "${error} Invalid domain name '${dom}'" && exit 1
        fi
    elif [[ $1 =~ ^[a-z][-a-z0-9.]*[a-z]$ ]] && [[ $1 =~ [.] ]]; then
        domain="$1"
    else
        echo -e "${error} Invalid domain name '$1'" && exit 1
    fi
}

prerequisites(){
    apt update &>/dev/null
    apt install -yy \
        dnsutils sssd sssd-tools libnss-sss libpam-sss krb5-user adcli samba-common-bin
}

fix_dns(){
    nodns_conf="/etc/NetworkManager/conf.d/no-dns.conf"

    if dpkg -l | grep -q network-manager && { [[ ! -f ${nodns_conf} ]] || ! (grep -qs "dns=none" "${nodns_conf}"); }; then
        echo -e "[main]\ndns=none" >"${nodns_conf}"
    fi

    [[ -L /etc/resolv.conf ]] && mv /etc/resolv.conf /etc/resolv.conf.o

    grep -qs "${domain}" /etc/resolv.conf ||
        echo -e "domain ${domain}\nsearch ${domain}\nnameserver ${dns_ip}" >/etc/resolv.conf

    dpkg -l | grep -q network-manager && systemctl restart NetworkManager
}

configure_ntp(){
    grep -qs "${ad_server}" /etc/systemd/timesyncd.conf || \
        sed "s/#NTP=/NTP=${ad_server}/" -i /etc/systemd/timesyncd.conf

    timedatectl set-ntp true
    systemctl restart systemd-timesyncd.service
    timedatectl --adjust-system-clock
}

configure_samba(){
    sed "s/workgroup = WORKGROUP/workgroup = ${workgroup}\n    client signing = yes\n    client use spnego = yes\n    kerberos method = secrets and keytab\n    realm = ${domain}\n    security = ads/" -i /etc/samba/smb.conf
}

configure_autocreate_user_home(){
    if ! (grep -qs "skel" /etc/pam.d/common-session); then
        echo "session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022" >>/etc/pam.d/common-session
    fi
}

join_domain(){
    kinit "${adminlogin}"
    net ads join -k "${domain}"
}

configure_sssd(){
    sed -e "s|\${realm}|${realm}|g" \
        -e "s|\$(hostname -s).\${domain}|$(hostname -s).${domain}|" \
        -e "s|\${ad_server}|${ad_server}|" \
        "${confpath}"/sssd/sssd.conf >/etc/sssd/sssd.conf

    chmod 600 /etc/sssd/sssd.conf

    systemctl restart sssd
}

scriptpath="$(dirname "$(realpath "$0")")"
resourcespath="$(dirname "${scriptpath}")"/resources
confpath="${resourcespath}"/templates

adminlogin=administrator

[[ $# -lt 1 ]] && echo -e "${error} Argument required" && usage && exit 0

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            test_domain "$2" && shift ;;
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
    echo -e "${error} Bad argument(s) '${positionals[@]}'" && usage && exit 1

[[ $(whoami) != root ]] && echo "${error} Need higher privileges." && usage && exit 1

prerequisites

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
[[ ${reboot} ]] && echo
[[ ! ${reboot} =~ [nN] ]] && reboot
