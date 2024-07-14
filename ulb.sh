#!/bin/bash

#################################################################################
# MIT License
#
# Copyright (c) 2024 saihon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#################################################################################

func_output_usage() {
    cat <<HELP

Usage: $NAME [options] [arguments]

Options:
  -c, --copy         Copy file to the $TARGET.
  -i, --interactive  Prompt before processiong.
  -l, --list         Show listing items in $TARGET.
  -m, --move         Move file to the $TARGET.
  -p, --permission   Set the file permission (Default: $PERMISSION)
  -r, --remove       Remove file in the $TARGET.
  -h, --help         Display this help and exit.
  -v, --version      Output version information and exit.

HELP
    exit 2
}

func_output_version() {
    echo "$NAME: $VERSION"
    exit 2
}

func_output_error_exit() {
    echo "Error: $1." 1>&2
    exit 1
}

func_split_by_equals() {
    IFS='=' read -ra ARRAY <<<"$1"
    OPTION="${ARRAY[0]}"
    if [[ -n "${ARRAY[1]}" ]]; then
        VALUE="${ARRAY[1]}"
        SKIP=false
    fi
}

func_verify_option() {
    [[ "$1" =~ ^-([^-]+|$) ]] && [[ "$1" =~ ^-(.*[^$PATTERN_SHORT]+.*|)$ ]] && func_output_error_exit "invalid option -- ‘$1‘"
    [[ "$1" =~ ^-{2,} ]] && [[ ! "$1" =~ ^-{2}($PATTERN_LONG)$ ]] && func_output_error_exit "invalid option -- ‘$1‘"
}

func_verify_required_option_error() {
    [[ -z "$VALUE" ]] && func_output_error_exit "required argument ‘$OPTION‘"
    "${SKIP}" && [[ "$VALUE" =~ ^-+ ]] && func_output_error_exit "invalid argument ‘$VALUE‘ for ‘$OPTION‘"
}

func_parse_arguments() {
    ##################################################
    O_COPY=false
    O_MOVE=false
    O_LIST=false
    O_REMOVE=false
    O_PERMISSION="$PERMISSION"
    O_INTERACTIVE=false

    local PATTERN_SHORT="clmpri"
    local PATTERN_LONG="copy|interactive|list|move|permission|remove"
    ##################################################

    while (($# > 0)); do
        case "$1" in
        -h | --help)
            func_output_usage
            ;;
        -v | --version)
            func_output_version
            ;;
        -*)
            local SKIP=true
            local OPTION="$1"
            local VALUE="$2"
            func_split_by_equals "$OPTION"
            func_verify_option "$OPTION"

            if [[ "$OPTION" =~ ^(-[^-]*l|--list$) ]]; then O_LIST=true; fi
            if [[ "$OPTION" =~ ^(-[^-]*i|--interactive$) ]]; then O_INTERACTIVE=true; fi
            if [[ "$OPTION" =~ ^(-[^-]*c|--copy$) ]]; then O_COPY=true; fi
            if [[ "$OPTION" =~ ^(-[^-]*m|--move$) ]]; then O_MOVE=true; fi
            if [[ "$OPTION" =~ ^(-[^-]*r|--remove$) ]]; then O_REMOVE=true; fi

            if [[ "$OPTION" =~ ^(-[^-]*p|--permission$) ]]; then
                func_verify_required_option_error
                [[ ! "$VALUE" =~ ^[0-7]{3}$ ]] && func_output_error_exit "Illigal permission -- ‘$VALUE‘"
                O_PERMISSION="$VALUE"
                "${SKIP}" && shift
            fi

            shift
            ;;
        *)
            ((++ARGC))
            ARGV+=("$1")
            shift
            ;;
        esac
    done

}

func_list() {
    ls -lA --color=auto "$TARGET"
    exit 0
}

func_run() {
    local CMD=""
    local VALUE="${ARGV[0]}"

    if [ "$(id -u)" -ne 0 ]; then
        CMD="sudo"
    fi

    case "$1" in
    copy | move)
        if [[ ! -f "$VALUE" ]]; then func_output_error_exit "no such file $VALUE"; fi

        [[ "$1" == "copy" ]] && CMD="$CMD cp"
        [[ "$1" == "move" ]] && CMD="$CMD mv"
        "${O_INTERACTIVE}" && CMD="$CMD -i"

        chmod "$O_PERMISSION" "$VALUE" && $CMD "$VALUE" "$TARGET"
        echo "$CMD $VALUE $TARGET"
        ;;
    remove)
        if [[ ! -f "$TARGET/$VALUE" ]]; then func_output_error_exit "no such file $TARGET/$VALUE"; fi

        CMD="$CMD rm"
        "${O_INTERACTIVE}" && CMD="$CMD -i"
        $CMD "$TARGET/$VALUE"

        echo "$CMD $TARGET/$VALUE"
        ;;
    esac

    exit 0
}

func_main() {
    NAME=$(basename "$0")
    VERSION="v0.0.2"

    TARGET="/usr/local/bin"
    readonly NAME VERSION TARGET

    local -i ARGC=0
    local -a ARGV=()

    local PERMISSION="755"

    func_parse_arguments "$@"

    "${O_LIST}" && func_list

    [[ "$ARGC" -eq 0 ]] && func_output_error_exit "File not specified"

    "${O_COPY}" && func_run "copy"
    "${O_MOVE}" && func_run "move"
    "${O_REMOVE}" && func_run "remove"
}

func_main "$@"
