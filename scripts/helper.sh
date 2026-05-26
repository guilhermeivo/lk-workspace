#!/usr/bin/env bash
set -e

GLOBAL_ARGS=("$@")

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

BOLD=$(tput bold)
PURPLE=$(tput setaf 5)
RESET=$(tput sgr0)

function eval_getopt() {
    local filename="$1"
    local extra_args=("${GLOBAL_ARGS[@]}")
    local -n ref=$2

    local short_options=""
    local long_options=""

    local itens=("${!ref[@]}")

    function get_long_option() {
        local array=("$@")
        echo "${array[0]}"
    }
    function get_short_option() {
        local array=("$@")
        local tmp="${array[1]}"
        if [[ -z "$tmp" ]]; then
            tmp="${array[0]:0:1}"
        fi
        echo "$tmp"
    }

    for ((i=0; i<${#itens[@]}; i++)); do
        item="${itens["$i"]}"

        IFS='|' read -ra parts <<< "$item"

        short_options+="$(get_short_option $parts)"
        long_options+="$(get_long_option $parts)"

        if (( i < ${#itens[@]} - 1 )); then
            long_options+=","
        fi
    done

    local getopt_output
    getopt_output=$(getopt \
        --options "${short_options}" \
        --longoptions "${long_options}" \
        --name "${filename}" \
        -- "${extra_args[@]}"
    )

    eval "set -- $getopt_output"

    while true; do
        local matched=false

        for item in "${itens[@]}"; do
            IFS='|' read -ra parts <<< "$item"

            local short_option="$(get_short_option $parts | tr -d ':')"
            local long_option="$(get_long_option $parts)"
            local shift_count=1
            local variable="${ref["$item"]}"

            if [[ "${long_option: -1}" == ":" ]]; then
                shift_count=2
            fi
            long_option=$(echo "$long_option" | tr -d ':')

            if [[ "$1" == "--" ]]; then
                shift
                matched=true
                break 2
            fi
            if [[ "$1" == "--$long_option" || "$1" == "-$short_option" ]]; then
                matched=true
                if [[ "$shift_count" -eq 2 ]]; then
                    printf -v "$variable" '%s' "$2"
                else
                    printf -v "$variable" '%s' true
                fi
                shift $shift_count
                break
            fi
        done

        if ! $matched; then
            echo "unknown option: $1"
            break
        fi
    done
}

function question() {
    local message="$1"

    read -r -p "$message [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            exit 1
            ;;
    esac
}

function error() {
    local message="$1"

    echo "${BOLD}${PURPLE}error:${RESET} $1"
    echo ""
    exit 1
}
