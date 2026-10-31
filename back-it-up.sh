#!/bin/bash

#set -x

VERSION='v.0.0.1a'
TITLE="back-it-up ${VERSION} - Simple Backup manager"

ESC=$'\x1B'
BS="${ESC}[D"

function usage()
{
	echo "${TITLE}

Usage: back-it-up [Options] <Command> [<Command Options>]

Options:
    -c, --color=WHEN     Colorize the output.
                         WHEN: never, auto or always.
    -h, --help           Show this help.

        --tldr           Too long, didn't read. Examples.

        --methods        Show how to implement other methods.

Commands:
    a, add             Add to backup.
       <id> <file> [<file> ...]

    b, backup          Backup, if a new version, all files already backedup.
       <id>

    l, list            With id, list files on backup.
       [<id>]          Without id, list all ids.

    v, versions        Versions of file on backup.
       <id> [<file> [<file> ...]]

    d, delete          Expurge files from backup.
       <id> <file> [-v|--versions <numbers>] [<file> ...]
       -v, --versions  Versions to expurge. If not set expurge all.
                       Versions separated with a comma. Ex: 1,2,3 

    shrink             Delete old versions keeping only the last version or
                       when indicate a file can optionaly selected the version.
       <id> [<file> [-v|--version <number>] [<file> ...]]
       -v, --version   Version to keep.

    r, restore         Restore from backup.
       <id> [<file> [-v|--version <number>] [-t|--target <file>] [<file> ...]]
       -v, --version   Version to restore.
       -t, --target    Target file to restore.

    s, send, upload    Upload backups.
       [<id> [<id> ...]]

    g, get, download   Download backups.
       [<id> [<id> ...]]

<id>    The identifier to the backup. Alhpanumeric, underscore, dot and dash.
<file>  Will be handled with the full path to the file.
        When restored, the -t|--target option points to a different local
        target file.

Enviroment variables:
    ${BOLD}BACK_IT_UP_VCOLORS${RESET} $([[ -n "${BACK_IT_UP_VCOLORS}" ]] && echo -ne "= ${WHITE}${BACK_IT_UP_VCOLORS}${RESET}\n                       ")  Variable with colors for versions.
                         The number of colors are unlimited.
                         The last color is only used for the last version.
                         Default: ${ESC}[2;36m2;36${RESET}:${ESC}[2;96m2;96${RESET}:${ESC}[0;36m0;36${RESET}:${ESC}[1;36m1;36${RESET}:${ESC}[0;96m0;96${RESET}:${ESC}[1;96m1;96${RESET}
                         For white (light) background these are sugestions:
                         BACK_IT_UP_VCOLORS=${ESC}[2;94;107m2;94${ESC}[0;30;107m:${ESC}[2;34;107m2;34${ESC}[0;30;107m:${ESC}[0;94;107m0;94${ESC}[0;30;107m:${ESC}[0;34;107m0;34${ESC}[0;30;107m:${ESC}[1;94;107m1;94${ESC}[0;30;107m:${ESC}[1;34;107m1;34${RESET}
                         BACK_IT_UP_VCOLORS=${ESC}[2;91;107m2;91${ESC}[0;30;107m:${ESC}[2;31;107m2;31${ESC}[0;30;107m:${ESC}[0;91;107m0;91${ESC}[0;30;107m:${ESC}[0;31;107m0;31${ESC}[0;30;107m:${ESC}[1;91;107m1;91${ESC}[0;30;107m:${ESC}[1;31;107m1;31${RESET}

    ${BOLD}BACK_IT_UP_LOCAL ${RESET} $([[ -z "${BACK_IT_UP_LOCAL}"  ]] && echo "${YELLOW}  not set variable${RESET}"                      || echo "= ${WHITE}${BACK_IT_UP_LOCAL}${RESET}" )
    ${BOLD}BACK_IT_UP_REMOTE${RESET} $([[ -z "${BACK_IT_UP_REMOTE}" ]] && echo    "${RED}  missing variable${RESET}"                      || echo "= ${WHITE}${BACK_IT_UP_REMOTE}${RESET}")
    ${BOLD}BACK_IT_UP_METHOD${RESET} $([[ -z "${BACK_IT_UP_METHOD}" ]] && echo "${YELLOW}  not set variable${RESET} default value: rsync" || echo "= ${WHITE}${BACK_IT_UP_METHOD}${RESET}")

    ${BOLD}BACK_IT_UP_LOCAL${RESET} default value: /home/${USER}/.config/back-it-up/backups

    For the default built-in method (${BOLD}rsync${RESET}):
    - ${BOLD}BACK_IT_UP_REMOTE${RESET} format: <host>:<port>:<directory>
      For example: example.com:22:/home/user/backups

    For other methods use: --methods"

	if [[ "${@}" != '' ]]; then
		echo
		fatal ${@}
	fi
}

function tldr()
{
	echo "${TITLE}

${YELLOW}- Add file (or a new version) to the backup:${RESET}
back-it-up a my-documents id.pdf

${YELLOW}- Backup new version of all files on the backup:${RESET}
back-it-up b my-documents

${YELLOW}- Show all versions of all files on backup:${RESET}
back-it-up v my-documents

${YELLOW}- Show all versions of a file on backup (you must be on same directory of the file):${RESET}
back-it-up v my-documents id.pdf

${YELLOW}- Show all versions of a file on backup (giving full path):${RESET}
back-it-up v my-documents /home/user/documents/id.pdf

${YELLOW}- Delete file on the backup (all versions):${RESET}
back-it-up d my-documents id.pdf

${YELLOW}- Delete file from backup of a specific version:${RESET}
back-it-up d my-documents id.pdf -v 1

${YELLOW}- Shrink the backup keeping last version of all files:${RESET}
back-it-up shrink my-documents

${YELLOW}- Shrink the backup keeping one version of the file:${RESET}
back-it-up shrink my-documents id.pdf -v 2

${YELLOW}- Restore file from backup:${RESET}
back-it-up r my-documents id.pdf

${YELLOW}- Restore file from backup of a specific version:${RESET}
back-it-up r my-documents id.pdf -v 1

${YELLOW}- Restore file from backup of a specific version on another file:${RESET}
back-it-up r my-documents /home/user/documents/id.pdf -v 1 -t /home/user/share/user-id.pdf

${YELLOW}- Send/Upload one or more backup to a remote location:${RESET}
back-it-up s my-documents my-photos

${YELLOW}- Send/Upload all backups to a remote location (see --methods option for more details):${RESET}
back-it-up s

${YELLOW}- Get/Download a specific backup from a remote location (see --methods option for more details):${RESET}
back-it-up g my-texts

${YELLOW}- Get/Download all backups from a remote location, based on load backups (see --methods option for more details):${RESET}
back-it-up g"
}

function methods()
{
	echo "${TITLE}

Methods... TODO"

	exit 0;
}

function fatal()
{
	echo "${RED}${@}${RESET}"
	exit 1
}

function check_id()
{
	# Syntaxe: check_id <id> [-|+]
	#  <id> The identifier to the backup
	#  -    Do not assign the filename to BACK_IT_UP_LOCAL
	#  +    Check if file exists

	[[ "${1}" == ''  || "${1}" =~ [^a-zA-Z0-9_.-] ]] && usage 'Invalid ID'
	[[ "${2}" != '-'                              ]] && BACK_IT_UP_LOCAL="${BACK_IT_UP_LOCAL}/${1}.tar"
	[[ "${2}" == '+' && ! -f "$BACK_IT_UP_LOCAL"  ]] && fatal "This backup doesn't exists"
}

function files_of_it()
{
	mapfile -t ${1} < <(tar --list -Pf ${BACK_IT_UP_LOCAL} "${2}" 2> /dev/null | sort -u)
}

function versions_of_it()
{
	if [[ "$1" == '' || "${1:0:1}" == '/' ]]; then
		                      tar --list -vPf "${BACK_IT_UP_LOCAL}" "${@}" 2> /dev/null | tr -s ' ' | sort -t ' ' -s -k 6,6
	else
		local var=${1}
		shift
		mapfile -t ${var} < <(tar --list -vPf "${BACK_IT_UP_LOCAL}" "${@}" 2> /dev/null | tr -s ' ' | sort -t ' ' -s -k 6,6)
	fi
}

function widths_of_it()
{
	local mode='all'  # Default
	local last=''
	local keys="${!FILES[@]}"
	local count=0
	local i=0
	local j
	local n
	local cols cols0 cols1 cols2 cols3 cols4 cols5
	local tmp

	case "${1}" in
		all|last)
			mode=$1
			shift
		;;
	esac

	if [ ${#WIDTHS[@]} -eq 0 ]; then
		VERSION=()
		WIDTHS=(0 0 4 0 0 0)
		for i in $keys; do
			IFS=' ' read -r cols0 cols1 cols2 cols3 cols4 cols5 <<< "${FILES[$i]}"
			cols=("$cols0" "$cols1" "$cols2" "$cols3" "$cols4" "$cols5")
			for (( j = 0; j < 5; j++ )); do
				n=${#cols[$j]}
				[ ${WIDTHS[$j]} -lt $n ] && WIDTHS[$j]=$n
			done
			if [ $i -gt 0 ]; then
				if [ "$last" != "${cols[5]}" ]; then
					VERSION[$(($i - 1))]=${count}
					[ ${WIDTHS[5]} -lt ${#count} ] && WIDTHS[5]=${#count}
					if [ $mode == 'all' ]; then
						for (( j = $i - 1; j > 0 && ${VERSION[$j]} > 1; j-- )); do
							VERSION[$j - 1]=$((${VERSION[$j]} - 1))
						done
					fi
					count=0
				elif [ $mode == 'last' ]; then
					unset FILES[$(($i - 1))]
				fi
			fi
			last=${cols[5]}
			((count++))
		done
		VERSION[$i]=${count}
		[ ${WIDTHS[5]} -lt ${#count} ] && WIDTHS[5]=${#count}
		for (( j = $i; j > 0 && ${VERSION[$j]} > 1; j-- )); do
			VERSION[$j - 1]=$((${VERSION[$j]} - 1))
		done

	elif [ $mode == 'last' ]; then
		for i in $keys; do
			IFS=' ' read -r cols0 cols1 cols2 cols3 cols4 cols5 <<< "${FILES[$i]}"
			tmp=("$cols0" "$cols1" "$cols2" "$cols3" "$cols4" "$cols5")
			if [ "${last}" != '' -a "$last" == "${cols[5]}" -a $mode == 'last' ]; then
				unset FILES[$(($i - 1))]
			fi
			last=${tmp[5]}
		done
	fi
}

function file_path()
{
	local cols=($1)
	echo "${cols[*]:5}"
echo "versions_of_it | cut -d' ' -f 6- | sed -E 's/ -> .+$//' | uniq -dc"
}

function print_it_files()
{
	local mode='all'  # Default mode
	local files
	local versions
	local ver_color=''
	local cols
	local keys
	local i
	local j
	local file

	case "${1}" in
		all|last)
			mode=$1
			shift
		;;
	esac

	if [ "${1}" == '' ]; then
		declare -n files='FILES'
	else
		declare -n files="${1}"
		shift
	fi

	widths_of_it $mode

	keys="${!files[@]}"
	for i in $keys; do
		cols=(${files[$i]})
		file="${cols[*]:5}"
		if [[ -n "${RESET}" ]]; then  # Avoid color effects processing when no color output
			if [[ $i == 0 || "$file" != "$(file_path "${files[$((i - 1))]}")"  ]]; then
				j=$((i + 1))
				while [[ "$file" == "$(file_path "${files[$j]}")" ]]; do : $((j++)); done
				versions=$((j - i))
			fi
			if [[ $versions -gt ${VERSION[$i]} ]]; then
				ver_color=${VCOLORS[$(( ( ( (( (${VERSION[$i]} * 1000) / ($versions - 1) ) * (${#VCOLORS[@]} - 1)) + 999 ) / 1000 ) - 1))]}
			else
				ver_color=${VCOLORS[-1]}
			fi
			if [ "${cols[0]:0:1}" == 'l' ]; then
				file="${file/ -> / ${YELLOW}->${RESET} }"
			fi
		fi
		printf "%-*s %-*s %*s %-*s %-*s [${ver_color}%*s${RESET}] %s\n" \
			"${WIDTHS[0]}" "${cols[0]}" \
			"${WIDTHS[1]}" "${cols[1]}" \
			"${WIDTHS[2]}" "${cols[2]}" \
			"${WIDTHS[3]}" "${cols[3]}" \
			"${WIDTHS[4]}" "${cols[4]}" \
			"${WIDTHS[5]}" "${VERSION[$i]}" \
			               "${file}"
	done
}

function print_it_filename()
{
	local msg=''
	local first=true
	local CR=$'\r'

	while [ ${#@} -gt 0 ]; do
		case "$1" in
			--up)      msg+="${CR}${ESC}[A";;
			--warning) msg+=" ${RED}${2}${RESET}"   ; shift;;
			--alert)   msg+=" ${YELLOW}${2}${RESET}"; shift;;
			--info)    msg+=" ${CYAN}${2}${RESET}"  ; shift;;
			*)
				if $first; then
					first=false
					msg+="${BLUE}${1}${RESET}:"
				else
					msg+=" ${1}"
				fi
			;;
		esac
		shift
	done

	echo "${msg}"
}

# # # # # #
# Actions #
# # # # # #

function add_it()
{
	local files=()
	local keys
	local i

	check_id "${1}"
	shift

	# Populate

	while [ ${#@} -gt 0 ]; do
		files+=("$(realpath -ms "${1}")")
		shift
	done

	# List

	keys="${!files[@]}"
	for i in $keys; do
		if [ ! -f "${files[$i]}" -a ! -L "${files[$i]}" ]; then
			print_it_filename "${files[$i]}" --warning 'File not found (or access denied)'
			unset files[$i]
			continue
		fi
		print_it_filename "${files[$i]}"
		result="$(tar --update -vPf ${BACK_IT_UP_LOCAL} "${files[$i]}")"
		if [[ "$result" == '' ]]; then
			echo -ne "\x1B[A\x1B[2K"
		else
			versions_of_it VERSIONS "${files[$i]}"
			if [[ ${#VERSIONS[@]} -eq 1 ]]; then
				print_it_filename --up "${files[$i]}" --info 'New file add'
			else
				print_it_filename --up "${files[$i]}" --info 'File updated' "(version ${#VERSIONS[@]})"
			fi
		fi
	done

	if [ "$SUDO_USER" != '' ]; then
		chown $SUDO_USER:$SUDO_USER ${BACK_IT_UP_LOCAL}
	fi
}

function backup_it()
{
	local keys
	local i

	if [[ "${1}" == '' ]]; then
:		# TODO all backups
	fi

	check_id "${1}" +
	shift

	# Populate

	files_of_it FILES

	# Backup

	keys="${!FILES[@]}"
	for i in $keys; do
		if [ ! -e "${FILES[$i]}" ]; then
			print_it_filename "${FILES[$i]}" --warning 'File not updated.' --alert "File not found (or access denied)"
			continue
		elif [ ! -r "${FILES[$i]}" ]; then
			print_it_filename "${FILES[$i]}" --warning 'File not updated.' --alert "Can't read"
			continue
		fi
		print_it_filename "${FILES[$i]}"
		result="$(tar --update -vPf "${BACK_IT_UP_LOCAL}" "${FILES[$i]}")"
		if [[ "$result" == '' ]]; then
			echo -ne "\x1B[A\x1B[2K"
		else
			versions_of_it VERSIONS "${FILES[$i]}"
			print_it_filename --up "${FILES[$i]}" --info 'File updated' "(version ${#VERSIONS[@]})"
		fi
	done

	if [ "$SUDO_USER" != '' ]; then
		chown $SUDO_USER:$SUDO_USER "${BACK_IT_UP_LOCAL}"
	fi
}

function list_it()
{
	local files=()

	if [[ "${1}" == "" ]]; then
		if [ ! -t 1 ]; then
			ls -1  ${BACK_IT_UP_LOCAL}/*.tar | xargs -n 1 basename | sed -E 's/\.tar$//'
		else
			du -bh ${BACK_IT_UP_LOCAL}/*.tar | sed -E 's/^([0-9.]+[A-Z]?[[:space:]]+)(\/[^\/]+)*\/([^\/]+)(\.tar)$/\1\3/' | column -t -R 1
		fi
		exit
	fi

	check_id "${1}" +
	shift

	# Populate

	while [ ${#@} -gt 0 ]; do
		files+=("$(realpath -ms "${1}")")
		shift
	done

	versions_of_it FILES "${files[@]}"

	# List

	print_it_files last
}

function versions_it()
{
	local files=()

	check_id "${1}" +
	shift

	# Populate

	while [ ${#@} -gt 0 ]; do
		files+=("$(realpath -ms "${1}")")
		shift
	done

	versions_of_it FILES "${files[@]}"

	# list

	print_it_files all
}

function delete_it()
{
	local files=()
	local file
	local occurrence
	local keys
	local i

	check_id "${1}" +
	shift

	# Populate

	while [ ${#@} -gt 0 ]; do
		[ "${1}" == '-v' -o "${1}" == '--versions' ] && fatal "Versions defined wihtout file"

		if [ "${2}" != '-v' -a "${2}" != '--versions' ]; then
			files+=("$(realpath -ms "${1}")")
			shift
			continue
		fi

		[[ ! "${3}" =~ ^[0-9]+(,[0-9]+)*$ ]] && fatal "Invalid versions number: ${3}"
		file=$(realpath -ms "${1}")
		mapfile -d '' occurrences < <(printf "%s\0" ${3//,/ } | sort -z -r)
		for occurrence in ${occurrences[@]}; do
			print_it_filename "${file}" --info 'Deleting version:' --alert "${occurrence}"
			tar --delete -Pf "${BACK_IT_UP_LOCAL}" "${file}" --occurrence=${occurrence}
		done
		shift 3
	done

	# Delete

	keys="${!files[@]}"
	for i in $keys; do
		print_it_filename "${files[$i]}" --info 'Deleting all versions' --alert '(bulk)'
	done

	if [[ "${files[@]}" != '' ]]; then
		tar --delete -Pf "${BACK_IT_UP_LOCAL}" "${files[@]}"
	fi
}

function shrink_it()
{
	local files=()
	local occurrences=()
	local versions=()
	local file
	local keys
	local i
	local n

	check_id "${1}" +
	shift

	# Populate

	if [ "${#@}" -eq 0 ] ; then
		while read n file; do
			# Keep last
			for (( i = n - 1; i >= 1; i-- )); do
				      files+=("${file}")
				occurrences+=("--occurrence=${i}")
			done
		done < <(versions_of_it | cut -d' ' -f 6- | sed -E 's/ -> .+$//' | uniq -dc)
	else
		while [ ${#@} -gt 0 ]; do
			[ "${1}" == '-v' -o "${1}" == '--version' ] && fatal "Version defined wihtout file"

			file="$(realpath -ms "${1}")"
			n=$(versions_of_it "${file}" | wc -l)
			shift

			# <file> <file>
			if [ "${1}" != '-v' -a "${1}" != '--version' ]; then
				# Keep last
				for (( i = n - 1; i >= 1; i-- )); do
					      files+=("$file")
					occurrences+=("--occurrence=${i}")
				done
				continue
			fi

			# <file> -v <number>
# Always true
#			if [  "${1}" == '-v' -o "${1}" == '--version' ]; then
				[[ ! "${2}" =~ ^[0-9]+$ ]] && fatal "Invalid version number: ${2}"
				for (( i = n; i >= 1; i-- )); do
					[[ $i -eq "${2}" ]] && continue  # Keep informed version
					      files+=("$file")
					occurrences+=("--occurrence=${i}")
				done
				shift 2
#				continue
#			fi
		done
	fi

	# Shrink

	keys="${!files[@]}"
	for i in $keys; do
		print_it_filename "${files[$i]}" --info "Deleting version ${occurrences[$i]/--occurrence=/}"
		tar --delete -Pf "${BACK_IT_UP_LOCAL}" ${occurrences[$i]} "${files[$i]}"
	done
}

function restore_it()
{
	local files=()
	local targets=()
	local occurrences=()
	local versions=()
	local keys
	local i

	check_id "${1}" +
	shift

	# Populate

	if [ "${#@}" -eq 0 ] ; then
		while read file; do
			files+=("${file}")
		done < <(versions_of_it | cut -d' ' -f 6- | sed -E 's/ -> .+$//' | uniq)
	else
		while [ ${#@} -gt 0 ]; do
			[ "${1}" == '-t' -o "${1}" == '--target'  ] && fatal "Target defined wihtout source file"
			[ "${1}" == '-v' -o "${1}" == '--version' ] && fatal "Version defined wihtout file"

			   files+=("$(realpath -ms "${1}")")
			versions+=("$(versions_of_it "${files[-1]}")")
			shift

			# <file> -t <path>
			# <file> -v <number>
			if [ "${1}" != '-t' -a "${1}" != '--target'  \
			  -a "${1}" != '-v' -a "${1}" != '--version' \
			]; then
					targets+=('')
				occurrences+=('')
				continue
			fi

			# <file> -t <path> -v <number>
			if [ "${3}" == '-v' -o "${3}" == '--version' ]; then
				[[ ! "${4}" =~ ^[0-9]+$ ]] && fatal "Invalid version number: ${4}"
				     targets+=("--transform=s/^.+\$/$(realpath -ms "${2}" | sed 's/\//\\\//g')/")
				 occurrences+=("--occurrence=${4}")
				versions[-1]+=" ${YELLOW}->${RESET} ${2}"
				shift 4
				continue
			fi

			# <file> -v <number> -t <path>
			if [ "${3}" == '-t' -o "${3}" == '--target' ]; then
				[[ ! "${2}" =~ ^[0-9]+$ ]] && fatal "Invalid version number: ${4}"
				 	targets+=("--transform=s/^.+\$/$(realpath -ms "${4}" | sed 's/\//\\\//g')/")
				 occurrences+=("--occurrence=${2}")
				versions[-1]+=" ${YELLOW}->${RESET} ${2}"
				shift 4
				continue
			fi

			# <file> -t <path>
			if [ "${1}" == '-t' -o "${1}" == '--target' ]; then
				     targets+=("--transform=s/^.+\$/$(realpath -ms "${2}" | sed 's/\//\\\//g')/")
				 occurrences+=('')
				versions[-1]+=" ${YELLOW}->${RESET} ${2}"
				shift 2
				continue
			fi

			# <file> -v <number>
# Always true
#			if [  "${1}" == '-v' -o "${1}" == '--version' ]; then
				[[ ! "${2}" =~ ^[0-9]+$ ]] && fatal "Invalid version number: ${2}"
					targets+=('')
				occurrences+=("--occurrence=${2}")
				shift 2
#				continue
#			fi
		done
	fi

	# Restore

	keys="${!occurrences[@]}"
	for i in $keys; do
		if [[ "${versions[$i]}" == '' ]]; then
			print_it_filename "${files[$i]}" --warning 'File not found (or access denied)'
			unset files[$i]
			continue
		fi

		local count=$(echo "${versions[$i]}" | wc -l)
		local occurrence=${count}

		if [ "${occurrences[$i]}" != '' ]; then
			if [ $count -eq 1 \
			  -o $count -le ${occurrences[$i]##*=} \
 			]; then
				# Have only one version or non last versions avaliable are lower than request
				[ "${targets[$i]}" == '' ] && continue # No target, go to bulk
				occurrences[$i]='' # Get last version
			else
				occurrence=${occurrences[$i]/--occurrence=/}
			fi
		fi

		if [ "${occurrences[$i]}" != '' \
		  -o "${targets[$i]}"     != '' \
		]; then
			print_it_filename "${files[$i]}" 'version' --info "${occurrence}" "of ${count} version$([ $count != 1 ] && echo s)"
			echo -e "${versions[$i]}" | \
				awk -F '/' -v OFS='/' -v occurrence=${occurrence} -v CYAN=${CYAN} -v RESET=${RESET} \
					'NR==occurrence { $2=$2 "[" CYAN occurrence RESET "] "; print }'
			tar --extract -Pf "${BACK_IT_UP_LOCAL}" "${files[$i]}" ${occurrences[$i]} ${targets[$i]}
			unset files[$i]
		fi
	done

	keys="${!files[@]}"
	for i in $keys; do
		print_it_filename "${files[$i]}" 'last version' --info "${BS}${occurrences[$i]/--occurrence=/ }" --alert '(bulk)'
	done

	if [[ "${files[@]}" != '' ]]; then
		tar --extract -Pf "${BACK_IT_UP_LOCAL}" "${files[@]}"
	fi
}

function upload_it()
{
	local remote="${BACK_IT_UP_REMOTE}"

	remote="${remote//@/${WHITE}@${BLUE}}"
	remote="${remote//:/${WHITE}:${BLUE}}"
	print_it_filename "${remote}" --info 'Send'

	ids_to_files_masked send "${@}"

	if [ "$BACK_IT_UP_METHOD" == 'rsync' ]; then
		back_it_up_method_rsync send ${FILES}  # WARN May be quoted
	else
echo "METHOD_FILE: ${METHOD_FILE}"
		fatal "Unknown method: $BACK_IT_UP_METHOD"
	fi
}

function download_it()
{
	print_it_filename "${BACK_IT_UP_LOCAL}" --info 'Get'

	ids_to_files_masked get ${@}

	if [ "$BACK_IT_UP_METHOD" == 'rsync' ]; then
		back_it_up_method_rsync get ${FILES}  # WARN May be quoted
	else
echo "METHOD_FILE: ${METHOD_FILE}"
		fatal "Unknown method: $BACK_IT_UP_METHOD"
	fi
}

function ids_to_files_masked()
{
	local mode=$1

	shift

	FILES=''
	if [ ${#@} -gt 0 ]; then
		while [ ${#@} -gt 0 ]; do
			check_id "${1}" -
			if [ $mode == 'send' -a ! -f "${BACK_IT_UP_LOCAL}/${1}.tar" ]; then
				print_it_filename "${BACK_IT_UP_LOCAL}/${1}.tar" --warning "Backup doesn't exists"
			else
				FILES+="${1},"
			fi
			shift
		done
	else
		FILES="$(cd "${BACK_IT_UP_LOCAL}"; ls *.tar | sed -zE 's/.tar(\n|$)/,/g')"
	fi
	[[ "$FILES" == ''  ]] && fatal "No backups"
	FILES="${FILES:0:$((${#FILES} - 1))}"
	[[ "$FILES" == *,* ]] && FILES="{${FILES}}"
	FILES+=".tar"
}

function back_it_up_method_rsync()
{
	# Sintaxy:
	#
	# back_it_up_method_<name>()
	#
	# $1     = action (get, send)
	# $FILES = files masked (/path/to/backups/{file1,file2}.tar
	#

	local remote
	local port
	local directory
	local sources
	local target
	local action=$1

	shift

	# Following the defined format: HOST:PORT:DIRECTORY
	IFS=: read remote port directory <<< "${BACK_IT_UP_REMOTE}"
	if [ "$port" == '' ]; then
		port=22
	elif [[ ! "$port" =~ ^[0-9]+$ ]]; then
		directory="${port}:${directory}"
		port=22
	fi

	case $action in
		send)
			sources=$(eval echo ${BACK_IT_UP_LOCAL}/${FILES})
			target="${remote}:${directory}"
		;;
		get)
			sources=$(eval echo ${remote}:${directory}/${FILES})
			target="${BACK_IT_UP_LOCAL}"
		;;
		*)
			fatal "Invalid method action: $action"
			return 1
		;;
	esac

#echo "${sources[@]// /$'\n'}"
	rsync -ahz --progress -e "ssh -p $port" ${sources} ${target}

	return 0
}

function set_colors()
{
	local COLORS='2;36:2;96:0;36:1;36:0;96:1;96'  # Default

	mode="${1:-auto}"
	[[ '|never|auto|always|' != *"|${mode}|"* ]] && usage "Invalid color option: ${mode}"

	  RESET=""
	  BLACK=""
	    RED=""
	  GREEN=""
	 YELLOW=""
	   BLUE=""
	MAGENTA=""
	   CYAN=""
	  WHITE=""

	VCOLORS=('')

	if [[ "$mode" == 'always' ]] || [[ "$mode" == 'auto' && -t 1 ]]; then
		  RESET="${ESC}[0m"
		   BOLD="${ESC}[1m"
		  BLACK="${ESC}[90m"
		    RED="${ESC}[91m"
		  GREEN="${ESC}[92m"
		 YELLOW="${ESC}[93m"
		   BLUE="${ESC}[94m"
		MAGENTA="${ESC}[95m"
		   CYAN="${ESC}[96m"

		if [ "$BACK_IT_UP_VCOLORS" != '' ]; then
			COLORS="$BACK_IT_UP_VCOLORS"
		fi
		if [[ "$COLORS" =~ ^[0-9]+(;[0-9]+)*(:[0-9]+(;[0-9]+)*)*$ ]]; then
			mapfile -d ':' -t VCOLORS < <(echo -n "${ESC}[${COLORS}m" | sed "s/:/m:${ESC}[/g")
		fi
	fi
}

function dependency()
{
	! which "$1" &> /dev/null && fail=true && echo "Missing: $1"
}

# # # # #
# Main  #
# # # # #

fail=false
for dep in tar realpath basename printf ls xargs sed du cut uniq column awk getent rsync; do
	dependency $dep
done
$fail && exit 1

set_colors auto

if [ "$BACK_IT_UP_LOCAL" == '' -a "$SUDO_USER" == '' ]; then
	BACK_IT_UP_LOCAL=$(getent passwd "$USER"      | cut -d: -f6)/.config/back-it-up/backups
elif [ "$BACK_IT_UP_LOCAL" == '' ]; then
	BACK_IT_UP_LOCAL=$(getent passwd "$SUDO_USER" | cut -d: -f6)/.config/back-it-up/backups
else
	BACK_IT_UP_LOCAL=$(realpath $BACK_IT_UP_LOCAL)
fi
mkdir -p ${BACK_IT_UP_LOCAL}

if [ "$BACK_IT_UP_METHOD" == '' -o "$BACK_IT_UP_METHOD" == 'rsync' ]; then
	BACK_IT_UP_METHOD=rsync
else
	METHOD_FILE=~/.config/back-it-up/methods/${BACK_IT_UP_METHOD}
	if [ -f ${METHOD_FILE} ]; then
		METHOD_FILE=${METHOD_FILE}
	elif [ -f ${METHOD_FILE}.sh ]; then
		METHOD_FILE=${METHOD_FILE}.sh
	elif [ -f ${METHOD_FILE}.bin ]; then
		METHOD_FILE=${METHOD_FILE}.bin
	else
		fatal "Can't find the method: ${METHOD_FILE}\{,.sh,.bin\}"
	fi
fi

while [[ ${1} != '' ]]; do
	case "${1}" in
		-h|--help   ) usage  ; exit;;
		   --tldr   ) tldr   ; exit;;
		   --methods) methods; exit;;

		-c=*|--color=*) set_colors "${1#*=}";;
		  -c|--color  ) [[ "${2:0:1}" != '-' ]] && shift && set_colors "$1" || set_colors auto;;

		a|add         ) shift; add_it      "${@}"; echo "${GREEN}Done${RESET} ${1}"; exit;;
		b|backup      ) shift; backup_it   "${@}"; echo "${GREEN}Done${RESET} ${1}"; exit;;
		l|list        ) shift; list_it     "${@}";                                   exit;;
		v|versions    ) shift; versions_it "${@}";                                   exit;;
		d|delete      ) shift; delete_it   "${@}"; echo "${GREEN}Done${RESET} ${1}"; exit;;
		  shrink      ) shift; shrink_it   "${@}"; echo "${GREEN}Done${RESET} ${1}"; exit;;
		r|restore     ) shift; restore_it  "${@}"; echo "${GREEN}Done${RESET} ${1}"; exit;;
		s|send|upload ) shift; upload_it   "${@}"; echo "${GREEN}Done${RESET} ${@}"; exit;;
		g|get|download) shift; download_it "${@}"; echo "${GREEN}Done${RESET} ${@}"; exit;;

		*) usage "Invalid option: ${1}";;
	esac
	shift
done
echo 'Try: back-it-up -h'
