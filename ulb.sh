#!/bin/bash

#
# /usr/local/bin/
# copy, move, remove, list
#
func_usr_local_bin() {
    local NAME="ulb"
    local VERSION="v0.0.1"
    local -i argc=0
    local -a argv=()
    local skip=false

    local TARGET="/usr/local/bin"
    local PERMISSION="755"
    local OWNER="root"
    local flag_copy=""
    local flag_move=""
    local flag_list=""
    local flag_remove=""
    local flag_interactive=""

    while (($# > 0))
    do
        case "$1" in
            -*)
                case "$1" in
                    -h|--help)
                        printf "\nUsage: %s [options] [arguments]\n\n" "$NAME"
                        echo "Options:"
                        printf "%-20s%s\n" '  -h, --help' 'display this help and exit'
                        printf "%-20s%s\n" '  -v, --version' 'output version information and exit'
                        printf "%-20s%s\n" '  -c, --copy' 'copy a file to the /usr/local/bin'
                        printf "%-20s%s\n" '  -m, --move' 'move a file to the /usr/local/bin'
                        printf "%-20s%s\n" '  -l, --list' 'use a long listing format. ls -l'
                        printf "%-20s%s\n" '  -r, --remove' 'remove a file in the /usr/local/bin'
                        printf "%-20s%s\n" '  -i, --interactive' 'prompt before processing'
                        printf "%-20s%s\n" '  -p, --permission' 'set the permission (default 755)'
                        printf "%-20s%s\n" '  -o, --owner' 'set the owner (default root)'
                        echo
                        return 0
                        ;;
                    -v|--version)
                        echo $NAME $VERSION
                        return 0
                        ;;
                    *)
                        pt_short="cmlripo"
                        if [[ "$1" =~ ^-([^-]+|$) ]] && [[ "$1" =~ ^-(.*[^$pt_short]+.*|)$ ]]; then
                            echo "Error: invalid short option $1" 1>&2
                            return -1
                        fi

                        pt_long="copy|move|list|remove|interactive|permission|owner"
                        if [[ "$1" =~ ^-{2,} ]] && [[ ! "$1" =~ ^-{2}($pt_long)$ ]]; then
                            echo "Error: invalid long option \`$1'" 1>&2
                            return -1
                        fi

                        # no argument
                        if [[ "$1" =~ ^(-[^-]*l|--list$) ]]; then
                            flag_list=1
                        fi

                        if [[ "$1" =~ ^(-[^-]*i|--interactive$) ]]; then
                            flag_interactive=1
                        fi

                        if [[ "$1" =~ ^(-[^-]*c|--copy$) ]]; then
                            flag_copy=1
                        fi

                        if [[ "$1" =~ ^(-[^-]*m|--move$) ]]; then
                            flag_move=1
                        fi

                        if [[ "$1" =~ ^(-[^-]*r|--remove$) ]]; then
                            flag_remove=1
                        fi

                        # required argument
                        if [[ "$1" =~ ^(-[^-]*p|--permission$) ]]; then
                            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                                echo "Error: option requires an argument \`$1'" 1>&2
                                return -1
                            fi
                            if [[ ! "$2" =~ ^[0-7]{3}$ ]]; then
                                echo "Error: invalid argument \`$2'" 1>&2
                                return -1
                            fi
                            PERMISSION="$2"
                            skip=true
                        fi

                        if [[ "$1" =~ ^(-[^-]*o|--owner$) ]]; then
                            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                                echo "Error: option requires an argument \`$1'" 1>&2
                                return -1
                            fi
                            OWNER="$2"
                            skip=true
                        fi

                        if $skip; then
                            skip=false
                            shift 2
                        else
                            shift
                        fi
                        ;;
                esac
                ;;
            *)
                ((++argc))
                argv+=( "$1" )
                shift
                ;;
        esac
    done

    #
    # ls command
    #
    if [ -n "$flag_list" ]; then
        ls -lA --color=auto "$TARGET"
        exit 0;
    fi


    if [[ $argc -gt 0 ]]; then
        local value=""
        local command="sudo"

        #
        # cp command
        #
        if [ -n "$flag_copy" ]; then
            command="$command cp"
            if [ -n "$flag_interactive" ]; then
                command="$command -i"
            fi

            for value in ${argv[@]}
            do
                if [[ -f "$value" ]]; then
                    sudo chmod "$PERMISSION" "$value" && \
                    sudo chown "$OWNER:$OWNER" "$value" && \
                    $command "$value" "$TARGET"
                else
                    echo "Error: no such file \`$value'"
                fi
            done
            exit 0;
        fi

        #
        # mv command
        #
        if [ -n "$flag_move" ]; then
            command="$command mv"
            if [[ -n "$flag_interactive" ]]; then
                command="$command -i"
            fi

            for value in ${argv[@]}
            do
                if [[ -f "$value" ]]; then
                    sudo chmod "$PERMISSION" "$value" && \
                    sudo chown "$OWNER:$OWNER" "$value" && \
                    $command "$value" "$TARGET"
                else
                    echo "Error: no such \`$value'"
                fi
            done
            exit 0;
        fi

        #
        # rm command
        #
        if [ -n "$flag_remove" ]; then
            command="$command rm"
            if [ -n "$flag_interactive" ]; then
                command="$command -i"
            fi

            for value in ${argv[@]}
            do
                if [[ -f "$TARGET/$value" ]]; then
                    $command "$TARGET/$value"
                else
                    echo "Error: no such \`$value' in the $TARGET"
                fi
            done
            exit 0;
        fi
    fi
}
func_usr_local_bin $@

