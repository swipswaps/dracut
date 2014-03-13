#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

find_udevd_binary() {
    local _bin _dir
    local _locations=(
        ${systemdutildir} ${udevdir} /sbin /usr/sbin
        )

    for _dir in $libdirs; do
        _locations+=( $_dir/systemd )
    done

    for _dir in "${_locations[@]}"; do
        for _bin in "$_dir"/{systemd-,}udevd; do
            echo "=>>> is udevd in $_bin?" >&2
            if [[ -x $_bin ]]; then
                echo "$_bin"
                return 0
            fi
        done
    done

    return 1
}

install_udevd_binary() {
    local _udevd=$(find_udevd_binary)

    if ! [[ $_udevd ]]; then
        derror "Cannot find [systemd-]udevd binary!"
        return 1
    fi

    [ -d ${initdir}/$systemdutildir ] || mkdir -p ${initdir}/$systemdutildir
    inst "$_udevd" || return 1
    if ! [[ -f  ${initdir}${systemdutildir}/systemd-udevd ]]; then
        ln -fs "$_udevd" ${initdir}${systemdutildir}/systemd-udevd || return 1
    fi

    return 0
}

# called by dracut
install() {
    local _i

    # Fixme: would be nice if we didn't have to guess, which rules to grab....
    # ultimately, /lib/initramfs/rules.d or somesuch which includes links/copies
    # of the rules we want so that we just copy those in would be best
    inst_multiple udevadm cat uname blkid \
        /etc/udev/udev.conf

    install_udevd_binary || exit 1

    inst_rules 50-udev-default.rules 60-persistent-storage.rules \
        61-persistent-storage-edd.rules 80-drivers.rules 95-udev-late.rules \
        60-pcmcia.rules \
        50-udev.rules 95-late.rules \
        50-firmware.rules \
        75-net-description.rules \
        80-net-name-slot.rules 80-net-setup-link.rules \
        "$moddir/59-persistent-storage.rules" \
        "$moddir/61-persistent-storage.rules"

    prepare_udev_rules 59-persistent-storage.rules 61-persistent-storage.rules
    # debian udev rules
    inst_rules 91-permissions.rules
    # eudev rules
    inst_rules 80-drivers-modprobe.rules

    for _i in \
        ${systemdutildir}/network/*.link \
        ${hostonly:+/etc/systemd/network/*.link} \
        ; do
        [[ -e "$_i" ]] && inst "$_i"
    done

    {
        for i in cdrom tape dialout floppy; do
            if ! egrep -q "^$i:" "$initdir/etc/group" 2>/dev/null; then
                if ! egrep "^$i:" /etc/group 2>/dev/null; then
                        case $i in
                            cdrom)   echo "$i:x:11:";;
                            dialout) echo "$i:x:18:";;
                            floppy)  echo "$i:x:19:";;
                            tape)    echo "$i:x:33:";;
                        esac
                fi
            fi
        done
    } >> "$initdir/etc/group"

    inst_multiple -o \
        ${udevdir}/ata_id \
        ${udevdir}/cdrom_id \
        ${udevdir}/create_floppy_devices \
        ${udevdir}/edd_id \
        ${udevdir}/firmware.sh \
        ${udevdir}/firmware \
        ${udevdir}/firmware.agent \
        ${udevdir}/hotplug.functions \
        ${udevdir}/fw_unit_symlinks.sh \
        ${udevdir}/hid2hci \
        ${udevdir}/path_id \
        ${udevdir}/input_id \
        ${udevdir}/scsi_id \
        ${udevdir}/usb_id \
        ${udevdir}/pcmcia-socket-startup \
        ${udevdir}/pcmcia-check-broken-cis

    inst_multiple -o /etc/pcmcia/config.opts

    [ -f /etc/arch-release ] && \
        inst_script "$moddir/load-modules.sh" /lib/udev/load-modules.sh

    inst_libdir_file "libnss_files*"

}

