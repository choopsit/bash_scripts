#!/usr/bin/env bash

author="Choops <choopsbd@gmail.com>"

c0="\e[0m"
ce="\e[31m"
cw="\e[33m"
ci="\e[36m"

error="${ce}Error${c0}:"

usage(){
    echo -e "${ci}Usage${c0}:"
    echo "  $(basename "$0") [OPTIONS]"
    echo -e "${ci}Options${c0}:"
    echo "  -h,--help:           Print this help"
    echo "  -i,--input <INPUT>:  Name input"
    echo "  -o,--ouput <OUTPUT>: Name output"
    echo "  -s,--simu:           Mode simulation"
    echo
}

test_input(){
    if [[ ! $1 ]] || [[ $1 = -* ]]; then
        echo -e "${error} No input given" && exit 1
    fi
    input="$1"
}

test_output(){
    if [[ ! $1 ]] || [[ $1 = -* ]]; then
        echo -e "${error} No output given" && exit 1
    fi
    output="$1"
}

[[ $# -lt 1 ]] && echo -e "${error} Argument required" && usage && exit 0

positionals=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            test_input "$2" && shift ;;
        -o|--output)
            test_output "$2" && shift ;;
        -s|--simu)
            simu=true ;;
        -h|--help)
            usage && exit 0 ;;
        -*)
            echo -e "${error} Unknown option '$1'" && usage && exit 1 ;;
        *)
            positionals+=("$1") ;;
    esac
    shift
done

[[ ${simu} ]] && echo -e "${ce}/${c0}!${ce}\\ ${cw}Simulation${c0}"
[[ ${input} ]] && echo -e "${ci}Input${c0}:  ${input}"
[[ ${output} ]] && echo -e "${ci}Output${c0}: ${output}"
[[ ${#positionals} -gt 0 ]] && echo -e "${ci}Positional arguments${c0}: ${positionals[@]}"
