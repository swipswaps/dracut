#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    local _fipsmodules _mod
    _fipsmodules="aead aes_generic aes-x86_64 ansi_cprng arc4 blowfish camellia cast6 cbc ccm "
    _fipsmodules+="chainiv crc32c crct10dif_generic cryptomgr crypto_null ctr cts deflate des des3_ede dm-crypt dm-mod "
    _fipsmodules+="ecb eseqiv fcrypt gcm ghash_generic hmac khazad lzo md4 md5 michael_mic rmd128 "
    _fipsmodules+="rmd160 rmd256 rmd320 rot13 salsa20 seed seqiv serpent sha1 sha224 sha256 sha256_generic "
    _fipsmodules+="sha384 sha512 sha512_generic tcrypt tea tnepres twofish wp256 wp384 wp512 xeta xtea xts zlib"

    mkdir -m 0755 -p "${initdir}/etc/modprobe.d"

    for _mod in $_fipsmodules; do
        if hostonly='' instmods -c -s $_mod; then
            echo $_mod >> "${initdir}/etc/fipsmodules"
            echo "blacklist $_mod" >> "${initdir}/etc/modprobe.d/fips.conf"
        fi
    done
}

# called by dracut
install() {
    local _dir
    inst_hook pre-trigger 01 "$moddir/fips-boot.sh"
    inst_hook pre-pivot 01 "$moddir/fips-noboot.sh"
    inst_script "$moddir/fips.sh" /sbin/fips.sh

    inst_multiple sha512hmac rmmod insmod mount uname umount fipscheck

    inst_libdir_file libsoftokn3.so libsoftokn3.so \
        libsoftokn3.chk libfreebl3.so libfreebl3.chk \
        libssl.so 'hmaccalc/sha512hmac.hmac' libssl.so.10

    inst_multiple -o prelink
    inst_simple /etc/system-fips
}

