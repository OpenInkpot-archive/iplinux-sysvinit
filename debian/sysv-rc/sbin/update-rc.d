#!/bin/sh

#
#	Function like update-rc.d but simpler & faster.
#	Usage: updatercd basename start|stop NN runlevel .
#   TODO: add 'remove' functionality so that the maintainer scripts are happy
#
updatercd() {

	if [ ! -f /etc/init.d/$1 ]
	then
		return
	fi

	if [ -d /usr/share/file-rc/. ] || [ -d /usr/lib/file-rc/. ] ||
	   [ ! -d /etc/rc2.d/. ]
	then
		update-rc.d "$@" > /dev/null
		return $?
	fi

	base=$1
	shift

	tmp="`echo /etc/rc?.d/[SK]??$base`"
	case "$tmp" in
		"/etc/rc?.d/[SK]??$base")
			;;
		*)
			return
			;;
	esac

	while [ "$1" != "" ]
	do
		if [ "$1" = stop ]
		then
			tlet=K
		else
			tlet=S
		fi
		case "$2" in
			?) lev=0$2 ;;
			*) lev=$2 ;;
		esac
		shift 2
		while [ "$1" != "." ]
		do
			cd /etc/rc$1.d
			ln -s ../init.d/$base $tlet$lev$base
			shift
		done
		shift
	done
}

updatercd "$@"

