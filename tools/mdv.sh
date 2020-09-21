#!/usr/bin/bash

description="Markdown Viewer"
author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
ci="\e[36m"

error="${ce}Error${c0}:"

usage(){
    echo -e "${ci}${description}\nUsage${c0}:"
    echo "./$(basename "$0") <FILE.md>"
    echo -e "${ci}Options${c0}:"
    echo " -h,--help: Print this help"
}

check_title(){
    pat=""
    for i in $(seq 8); do
        pat+="#"
        if [[ ${line} = "${pat} "* ]]; then
            hn="$(eval echo "\${h${i}}")"
            line="${hn}${line/"${pat} "/}" && break
        fi
    done
}

check_list(){
    [[ ${line} =~ ^[0-9]*\.\  ]] && line="${li} ${line}"
    [[ ${line} =~ ^[\*-]\  ]] && line="${li} ${line/\*/-}"
}

check_decoration_in_line(){
    bd=""
    it=""
    us=""

    for color in "${colorlist[@]}"; do
        [[ ${line} = "${color}"* ]] && lc="${color}"
    done
    [[ ${lc} ]] || lc="${df}"

    [[ ${lc} = "${df}" ]] && bd="\e[1;2;37m" && it="\e[3;37m" && us="\e[4;37m"
    [[ ${lc} = "${li}" ]] && bd="\e[1;2;36m" && it="\e[3;36m" && us="\e[4;36m"

    linelist=(${line})
    myline=""
    sep=""
    for word in "${linelist[@]}"; do
        unset iquote
        unset oquote
        unset iponct
        unset oponct
        unset iqponct
        unset oqponct
        iponctlist=("(" "[" "{")
        oponctlist=("." "," ";" "?" "!" ":" ")" "]" "}")

        for ipct in "${iponctlist[@]}"; do
            if [[ ${word} = "${ipct}"* ]]; then
                iponct="${ipct}" && word="${word:1}"
            fi
        done
        for opct in "${oponctlist[@]}"; do
            if [[ ${word} = *"${opct}" ]]; then
                oponct="${opct}" && word="${word::-1}"
            fi
        done
        [[ ${word} = \"* ]] && iquote='"' && word="${word:1}"
        [[ ${word} = *\" ]] && oquote='"' && word="${word::-1}"
        [[ ${word} = \'* ]] && iquote="'" && word="${word:1}"
        [[ ${word} = *\' ]] && oquote="'" && word="${word::-1}"
        for iqpct in "${iponctlist[@]}"; do
            if [[ ${word} = "${iqpct}"* ]]; then
                iqponct="${iqpct}" && word="${word:1}"
            fi
        done
        for oqpct in "${oponctlist[@]}"; do
            if [[ ${word} = *"${oqpct}" ]]; then
                oqponct="${oqpct}" && word="${word::-1}"
            fi
        done
        [[ ${word} = __*__ ]] && word="${bd}${word//__/}${lc}"
        [[ ${word} = __* ]] && word="${bd}${word/__/}${bd}"
        [[ ${word} = *__ ]] && word="${bd}${word/__/}${lc}"
        [[ ${word} = \*\**\*\* ]] && word="${bd}${word//\*\*/}${lc}"
        [[ ${word} = \*\** ]] && word="${bd}${word/\*\*/}${bd}"
        [[ ${word} = *\*\* ]] && word="${bd}${word/\*\*/}${lc}"
        [[ ${word} = _*_ ]] && word="${it}${word//_/}${lc}"
        [[ ${word} = _* ]] && word="${it}${word/_/}${it}"
        [[ ${word} = *_ ]] && word="${it}${word/_/}${lc}"
        [[ ${word} = \**\* ]] && word="${it}${word//\*/}${lc}"
        [[ ${word} = \** ]] && word="${it}${word/\*/}${it}"
        [[ ${word} = *\* ]] && word="${it}${word/\*/}${lc}"
        [[ ${word} = \`*\` ]] && word="${cc} ${word//\`/} ${lc}"
        [[ ${word} = \`* ]] && word="${cc} ${word/\`/}${cc}"
        [[ ${word} = *\` ]] && word="${cc}${word/\`/} ${lc}"
        myline+="${sep}${iponct}${iquote}${iqponct}${word}${oqponct}${oquote}${oponct}"
        sep=" "
    done
    line="${myline}"
}

[[ $# -lt 1 ]] && echo -e "${error} Need an 1 argument" && usage && exit 1
[[ $# -gt 1 ]] && echo -e "${error} Too many arguments" && usage && exit 1

arg=("$@")
for i in $(seq 0 $((${#arg[@]}-1))); do
    [[ ${arg[$i]} =~ ^-(h|-help)$ ]] && usage && exit 0
done

myfile="$1"

df="\e[0;37m"

h1="\e[1;32m"
h2="\e[4;32m"
h3="\e[0;32m"
h4="\e[3;32m"
h5="\e[1;2;32m"
h6="\e[4;2;32m"
h7="\e[0;2;32m"
h8="\e[3;2;32m"

li="\e[0;36m"

cc="\e[0;33;40m"

colorlist=("${df}" "${bd}" "${it}" "${us}" "${h1}" "${h2}" "${h3}" "${h4}" "${h5}" "${h6}" \
    "${h7}" "${h8}" "${li}" "${cc}")

#echo -e "${h1}Title${df}"
#echo -e "${h2}Subtitle${df}"
#echo -e "${h3}Subsubtitle${df}"
#echo -e "${h4}Subsubsubtitle${df}"
#echo -e "${h5}Subsubsubsubtitle${df}"
#echo -e "${h6}Subsubsubsubsubtitle${df}"
#echo -e "${h7}Subsubsubsubsubsubtitle${df}"
#echo -e "${h8}Subsubsubsubsubsubsubtitle${df}"
#
#echo -e "${df}Normal text${df}"
#echo -e "${bd}Bold text${df}"
#echo -e "${it}Italic text${df}"
#echo -e "${us}Underscored text${df}"
#
#echo -e "${li} 1. ordered list element${df}"
#echo -e "${li} - unordered list element${df}"

clear

while read line; do
    check_title
    check_list
    check_decoration_in_line
    echo -e "${df}${line}${df}"
done <"${myfile}"
