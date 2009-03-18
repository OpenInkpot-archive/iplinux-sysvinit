#
# checkroot.sh	Check to root file system.
#
# Version:	@(#)checkroot.sh  2.85-23  29-Jul-2004  miquels@cistron.nl
#

VERBOSE=yes

PATH=/lib/init:/bin:/sbin

#
#	Helper: is a directory writable ?
#
dir_writable () {
	if [ -d "$1/" ] && [ -w "$1/" ] && touch -a "$1/" 2>/dev/null
	then
		return 0
	fi
	return 1
}

swapon -a

ROOT=$(sed -e '/^#/d; /[^ \t]\+[ \t]\+\/[ \t]/q; d' < /etc/fstab)
if [ -n "$ROOT" ]; then
    fstabroot=$(echo "$ROOT" | awk '{print $1}')
    rootopts=$(echo "$ROOT" | awk '{print $4}')
    mount -n -o remount,$rootopts $fstabroot /
else
    # Well, let's just remount root.
    mount -n -o remount,rw /
fi

#
#	We only create/modify /etc/mtab if the location where it is
#	stored is writable.  If /etc/mtab is a symlink into /proc/
#	then it is not writable.
#
init_mtab=no
if [ -L /etc/mtab ]
then
    MTAB_PATH="`readlink /etc/mtab`"
else
    MTAB_PATH="/etc/mtab"
fi

case "$MTAB_PATH" in
	/proc/*)
		;;
	/*)
		if dir_writable ${MTAB_PATH%/*}
		then
			:> $MTAB_PATH
			rm -f ${MTAB_PATH}~
			init_mtab=yes
		fi
		;;
	"")
		if [ "$MTAB_PATH" ] ; then
			echo "checkroot.sh: cannot initialize $MTAB_PATH" >&2
		else
			echo "checkroot.sh: cannot initialize the mtab file" >&2
		fi
		;;
esac

if [ "$init_mtab"  = yes ]
then
	[ "$roottype" != none ] &&
		mount -f -o $rootopts -t $roottype $fstabroot /
	[ -n "$devfs" ] && mount -f $devfs
	. /etc/init.d/mountvirtfs
fi

: exit 0
