#!/bin/sh

# update-rc.d
# Copyright (C) 2010 Mikhail Gusarov <dottedmag@dottedmag.net>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA

ETCRC=${ETCRC:-/etc/rc}
INITD=${INITD:-/etc/init.d}

DRY_RUN=
FORCE=
NAME=

findlinks() {
  for runlevel in $@; do
    for f in $(find "${ETCRC}${runlevel}.d" -maxdepth 1 -mindepth 1 -type l); do
      if [ x$(readlink -f "$f") = "x$INITD/$NAME" ]; then
        echo $f
      fi
    done
  done
}

remove() {
  runlevels="0 1 2 3 4 5 6 S"

  if [ -e "$INITD/$NAME" ] && [ -z $FORCE ]; then
    echo "Unable to remove $NAME: $INITD/$NAME still exists."
    exit 1
  fi

  for f in $(findlinks $runlevels); do
    echo "Removing $f"
    if [ -z $DRY_RUN ]; then
      rm -f "$f"
    fi
  done
}

startstop() {
  while [ $# -ne 0 ]; do
    mode="$1"
    case "$mode" in
      start) prefix=S;;
      stop) prefix=K;;
    esac

    nn="$2"
    shift 2

    while [ $# -ne 0 ] && [ "x$1" != "x." ]; do
      runlevel="$1"
      shift

      if [ -n "$(findlinks $runlevel)" ]; then
        echo "Skipping $mode on runlevel $runlevel: start/stop link exists."
      else
        echo "Creating link $ETCRC$runlevel.d/$prefix$nn$NAME -> $INITD/$NAME"
        if [ -z $DRY_RUN ]; then
          ln -s $INITD/$NAME ${ETCRC}$runlevel.d/$prefix$nn$NAME
        fi
      fi
    done
    shift
  done
}

defaults() {
  start_runlevels="2 3 4 5"
  stop_runlevels="0 1 6"
  startn=20
  stopn=20

  if [ $# -eq 1 ]; then
    startn=$1
    stopn=$1
  fi

  if [ $# -eq 2 ]; then
    startn=$1
    stopn=$2
  fi

  startstop start $startn $start_runlevels . stop $stopn $stop_runlevels .
}

enabledisable() {
  mode="$1"
  shift

  if [ $# -ne 0 ]; then
    runlevels="$@"
  else
    runlevels="S 2 3 4 5"
  fi

  for f in $(findlinks $runlevels) ;do
    dir=$(dirname "$f") # /etc/rc2.d/S70foo -> /etc/rc2.d
    base=$(basename "$f") # /etc/rc2.d/S70foo -> S70foo
    suffix=${base#???} # S70foo -> foo
    num=${base#[SK]} # S70foo -> 70foo
    num=${num%$suffix} # 70foo -> 70
    new_num=$((100 - $num)) # 70 -> 30

    case "$mode-$base" in
      enable-K*)
        new_f="${dir}/S${new_num}${suffix}"
        echo "Enabling $f -> $new_f"
        if [ -z $DRY_RUN ]; then
          mv -f "$f" "$new_f"
        fi
        ;;
      disable-S*)
        new_f="${dir}/K${new_num}${suffix}"
        echo "Disabling $f -> $new_f"
        if [ -z $DRY_RUN ]; then
          mv -f "$f" "$new_f"
        fi
        ;;
    esac
  done
}

usage() {
  echo "Usage:"
  echo "  update-rc.d [-n] [-f] <name> remove"
  echo "  update-rc.d [-n] <name> defaults [<NN> | <SS> <KK>]"
  echo "  update-rc.d [-n] <name> start|stop <NN> <runlevel> [<runlevel>]... . "
  echo "      start|stop <NN> <runlevel> [<runlevel>]... . ..."
  echo "  update-rc.d [-n] <name> disable|enable [S|2|3|4|5]"
}

updatercd() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -n) DRY_RUN=1;;
      -f) FORCE=1;;
      *) break;;
    esac
    shift
  done

  if [ $# -lt 2 ]; then
    usage
    exit 1
  fi

  NAME="$1"
  shift

  action="$1"
  shift

  case "$action" in
    remove)
      remove "$@";;
    defaults)
      defaults "$@";;
    start|stop)
      startstop "$action" "$@";;
    enable|disable)
      enabledisable "$action" "$@";;
    *)
      echo "Unknown action: $action"
      usage
      exit 1;;
  esac
}

updatercd "$@"
