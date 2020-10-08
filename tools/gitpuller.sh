#!/usr/bin/env bash

description="Operate a 'git pull' on all git repos in a targetted folder"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cw="\e[33m"
ci="\e[36m"

error="${ce}Error${c0}:"
warning="${cw}Warning${c0}:"

set -e

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "  $(basename "$0") [OPTION] [REPO_FOLDER (default: current path)]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help: Print this help"
    echo
}

test_folder(){
    [[ ! -d "$1" ]] && echo -e "${error} '$1' is not a folder" && exit 1
    gitfolder="$1"
}

test_pullpolicy(){
    echo -e "${warning} Rebase is not default on 'git pull' for '$(basename "$1")'"
    read -p "Change this [y/N] ?" -rn1 change
    [[ ${change} ]] && echo
    if [[ ${change} =~ [yY] ]]; then
        pushd "$1" &>/dev/null
        git config pull.rebase true
        popd &>/dev/null
    else
        read -p "Ignore '$1' [Y/n] ? " -rn1 norepo
        if [[ ${norepo} ]]; then echo; fi
    fi
}

test_repo(){
    norepo=n
    grep -q "rebase = true" "$1"/.git/config || test_pullpolicy "$1"
    if [[ ${norepo} =~ [nN] ]]; then
        repolist+=("$1")
    fi
}

list_repos(){
    [[ ${gitfolder} ]] || gitfolder="$(pwd)"
    repolist=()
    for folder in "${gitfolder}"/*; do
        [[ -d "${folder}"/.git ]] && test_repo "${folder}"
    done
    if [[ ${#repolist[@]} -lt 1 ]]; then
        echo "No git repo found in '${gitfolder}'" && exit 0
    fi
}

pull_repos(){
    for repo in "${repolist[@]}"; do
        echo -e "${ci}$(basename "${repo}")${c0}: "
        pushd "${repo}" &>/dev/null
        git pull
        popd &>/dev/null
    done
}

[[ $(hostname -s) = mrchat ]] && gitfolder=~/Work/git

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

[[ ${#positionals[@]} -gt 1 ]] && echo -e "${error} Too many arguments" && usage && exit 1
[[ ${#positionals[@]} -eq 1 ]] && gitfolder="${positionals[0]}"

list_repos
pull_repos
