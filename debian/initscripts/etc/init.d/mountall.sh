#
# mountall.sh	Mount all filesystems.
#
# Version:	@(#)mountall.sh  2.85-23  29-Jul-2004  miquels@cistron.nl
#

VERBOSE=yes
TMPTIME=0
[ -f /etc/default/rcS ] && . /etc/default/rcS
. /etc/init.d/bootclean.sh

#
# Mount local file systems in /etc/fstab.
#
[ "$VERBOSE" != no ] && echo "Mounting local filesystems..."
mount -av -t nonfs,nonfs4,nosmbfs,nocifs,noncp,noncpfs,nocoda 2>&1 |
	egrep -v '(already|nothing was) mounted'

case `uname -s` in
	*FreeBSD)
		INITCTL=/etc/.initctl
		;;
	*)
		INITCTL=/dev/initctl
		;;
esac

#
# We might have mounted something over /dev, see if /dev/initctl is there.
#
if [ ! -p $INITCTL ]
then
	rm -f $INITCTL
	mknod -m 600 $INITCTL p
fi
[ "`readlink /sbin/init`" != "/bin/busybox" ] && kill -USR1 1

#
# Execute swapon command again, in case we want to swap to
# a file on a now mounted filesystem.
#
doswap=yes
case "`uname -sr`" in
	Linux\ 2.[0123].*)
		if grep -qs resync /proc/mdstat
		then
			doswap=no
		fi
		;;
esac
if [ $doswap = yes ]
then
	swapon -a 2> /dev/null
fi

#
#	Clean /tmp, /var/lock, /var/run
#
bootclean mountall

: exit 0

