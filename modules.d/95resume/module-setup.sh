#!/bin/bash

# called by dracut
check() {
    # No point trying to support resume, if no swap partition exist
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs =~ ^(swap|swsuspend|swsupend)$ ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
cmdline() {
    local _resume

    for dev in "${!host_fs_types[@]}"; do
        [[ ${host_fs_types[$dev]} =~ ^(swap|swsuspend|swsupend)$ ]] || continue
        _resume=$(shorten_persistent_dev "$(get_persistent_dev "$dev")")
        [[ -n ${_resume} ]] && printf " resume=%s" "${_resume}"
    done
}

# called by dracut
install() {
    local _bin

    if [[ $hostonly_cmdline == "yes" ]]; then
        cmdline  >> "${initdir}/etc/cmdline.d/95resume.conf"
        echo  >> "${initdir}/etc/cmdline.d/95resume.conf"
    fi

    # Optional uswsusp support
    for _bin in /usr/sbin/resume /usr/lib/suspend/resume /usr/lib/uswsusp/resume
    do
        [[ -x "${_bin}" ]] && {
            inst "${_bin}" /usr/sbin/resume
            [[ $hostonly ]] && [[ -f /etc/suspend.conf ]] && inst -H /etc/suspend.conf
            break
        }
    done

    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 10 "$moddir/parse-resume.sh"
    else
        inst_script "$moddir/parse-resume.sh" /lib/dracut/parse-resume.sh
    fi

    inst_script  "$moddir/resume.sh" /lib/dracut/resume.sh
}

