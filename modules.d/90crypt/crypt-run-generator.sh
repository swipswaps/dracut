#!/bin/sh

. /lib/dracut-lib.sh

dev=$1
luks=$2

if [ -f /etc/crypttab ]; then
    while read l rest; do
        strstr "${l##luks-}" "${luks##luks-}" && exit 0
    done < /etc/crypttab
fi

echo "$luks $dev" >> /etc/crypttab
if [ -x /lib/systemd/system-generators/systemd-cryptsetup-generator ] &&
        command -v systemctl >/dev/null; then
    /lib/systemd/system-generators/systemd-cryptsetup-generator
    systemctl daemon-reload
    systemctl start cryptsetup.target
fi
exit 0
