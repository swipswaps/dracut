#!/bin/sh

if [ -e /etc/multipath.conf ]; then
    modprobe dm-multipath
    multipathd -B || multipathd
    need_shutdown
else
    rm -- /etc/udev/rules.d/??-multipath.rules 2>/dev/null
fi

