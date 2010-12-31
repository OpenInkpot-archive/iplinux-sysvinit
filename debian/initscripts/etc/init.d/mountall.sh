# -*- mode:sh -*-

mount -av -t nonfs,nonfs4,nosmbfs,nocifs,noncp,noncpfs,nocoda 2>&1 |
	egrep -v '(already|nothing was) mounted'

swapon -a 2> /dev/null
