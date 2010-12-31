# -*- mode: sh -*-

if [ -f /etc/hostname ]
then
	hostname -F /etc/hostname
fi
