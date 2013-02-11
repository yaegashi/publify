#!/bin/sh

set -e

cd "${0%/*}/../.."

CONFIG=$PWD/config/unicorn.rb
PIDFILE=$PWD/tmp/pids/unicorn.pid

if ! test -r $CONFIG; then
        echo "E: Configuration $CONFIG not found!" >&2
        exit 1
fi

case "$1" in
start)
        bundle exec unicorn_rails -D -c $CONFIG
        ;;
stop)
        kill -QUIT $(cat $PIDFILE)
        ;;
reload)
        kill -USR2 $(cat $PIDFILE)
        sleep 1
        kill -QUIT $(cat $PIDFILE.oldbin)
        ;;
*)
        echo "Usage: $0 start|stop|reload" >&2
        exit 1
        ;;
esac
