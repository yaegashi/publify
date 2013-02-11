#!/bin/sh

set -e

cd "${0%/*}/../.."

if test $# -eq 0; then
        echo "Usage: $0 <USER> <COMMAND>..." >&2
        exit 1
fi

USER=$1
shift

if test $# -gt 0; then
        CMD=$1
        shift
        OPSDIR=$PWD/script/ops
        REALCMD=$OPSDIR/$CMD
        if ! test -x "$REALCMD"; then
                echo "E: Unable to exec $CMD in $OPSDIR" >&2
                exit 1
        fi
        set -- $REALCMD "$@"
fi

sudo -k
exec sudo -u $USER -i "$@"
