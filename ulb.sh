#!/bin/bash
############################################################
# SPECIFICATION:
#  Longer options can be specified.
#    $ command --alpha
#
#  Shorter options can be specified.
#    $ command -a
#
#  Multiple short options can be mixed and specified.
#    $ command -abc
#
#  By using '=', can specify arguments starting with '-'.
#    $ command -a=-100
#    $ command --alpha=-100
############################################################

func_output_usage() {
	cat << HELP

Usage: $NAME [options] [arguments]

Options:
  -c, --copy         Copy file to the /usr/local/bin.
  -i, --interactive  Prompt before processiong.
  -l, --list         Show listing items in /usr/local/bin.
  -m, --move         Move file to the /usr/local/bin.
  -o, --owner        Set the name of owner (Default: $OWNER)
  -p, --permission   Set the file permission (Default: $PERMISSION)
  -r, --remove       Remove file in the /usr/local/bin.
  -h, --help         Display this help and exit.
  -v, --version      Output version information and exit.

HELP
	exit 2
}

func_output_version() {
	echo "$NAME: $VERSION"
	exit 2
}

func_output_error() {
	echo "Error: $1." 1>&2
	exit 1
}

func_split_by_equals() {
	IFS='=' read -ra ARRAY <<< "$1"
	OPTION="${ARRAY[0]}"
	if [[ -n "${ARRAY[1]}" ]]; then
		VALUE="${ARRAY[1]}"
		SKIP=false
	fi
}

func_verify_option() {
	[[ "$1" =~ ^-([^-]+|$) ]] && [[ "$1" =~ ^-(.*[^$PATTERN_SHORT]+.*|)$ ]] && func_output_error "invalid option -- ‘$1‘"
	[[ "$1" =~ ^-{2,} ]] && [[ ! "$1" =~ ^-{2}($PATTERN_LONG)$ ]] && func_output_error "invalid option -- ‘$1‘"
}

func_verify_required_option_error() {
	[[ -z "$VALUE" ]] && func_output_error "required argument ‘$OPTION‘"
	"${SKIP}" && [[ "$VALUE" =~ ^-+ ]] && func_output_error "invalid argument ‘$VALUE‘ for ‘$OPTION‘"
}

func_parse_arguments() {
	##################################################
	O_COPY=false
	O_MOVE=false
	O_LIST=false
	O_REMOVE=false
	O_OWNER="$OWNER"
	O_PERMISSION="$PERMISSION"
	O_INTERACTIVE=false

	local PATTERN_SHORT="clmopri"
	local PATTERN_LONG="copy|list|move|owner|permission|remove|"
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
					[[ ! "$VALUE" =~ ^[0-7]{3}$ ]] && func_output_error "Illigal permission -- ‘$VALUE‘"
					O_PERMISSION="$VALUE"
					"${SKIP}" && shift
				fi

				if [[ "$OPTION" =~ ^(-[^-]*o|--owner$) ]]; then
					func_verify_required_option_error
					O_OWNER="$VALUE"
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

func_exec_ulb_list() {
	ls -lA --color=auto "$TARGET"
	exit 0
}

func_exec_ulb_file_handler() {
	local CMD="sudo"

	local VALUE="${ARGV[0]}"

	case "$1" in
		copy | move)
			if [[ ! -f "$VALUE" ]]; then func_output_error "no such file $VALUE"; fi

			[[ "$1" == "copy" ]] && CMD="$CMD cp"
			[[ "$1" == "move" ]] && CMD="$CMD mv"
			"${O_INTERACTIVE}" && CMD="$CMD -i"

			sudo chmod "$O_PERMISSION" "$VALUE" \
				&& sudo chown "$O_OWNER:$O_OWNER" "$VALUE" \
				&& $CMD "$VALUE" "$TARGET"

			echo "$CMD $VALUE $TARGET"
			;;
		remove)
			if [[ ! -f "$TARGET/$VALUE" ]]; then func_output_error "no such file $TARGET/$VALUE"; fi

			CMD="$CMD rm"
			"${O_INTERACTIVE}" && CMD="$CMD -i"
			$CMD "$TARGET/$VALUE"

			echo "$CMD $TARGET/$VALUE"
			;;
	esac

	exit 0
}

func_exec_ulb() {
	local TARGET="/usr/local/bin"

	"${O_LIST}" && func_exec_ulb_list

	[[ "$ARGC" -eq 0 ]] && func_output_error "File not specified"

	"${O_COPY}" && func_exec_ulb_file_handler "copy"
	"${O_MOVE}" && func_exec_ulb_file_handler "move"
	"${O_REMOVE}" && func_exec_ulb_file_handler "remove"
}

func_main() {
	local NAME=$(basename "$0")
	local VERSION="v1.0"

	local -i ARGC=0
	local -a ARGV=()

	local PERMISSION="755"
	local OWNER="root"

	func_parse_arguments "$@"

	func_exec_ulb
}

func_main "$@"
