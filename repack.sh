#!/usr/bin/env sh

export TERM=xterm

for image in `find imgs -name recovery.img -o -name boot.img -o -name vendor_boot.img`;do
    imagedirname=`dirname $image`
    imagepartname=`basename $image`
    imagepartname=${imagepartname%%.*}
    AIK-Linux/unpackimg.sh --nosudo $image
    ramdisk=AIK-Linux/ramdisk
    for prop_file in `grep -rEl '^(ro.debuggable|ro.secure|ro.adb.secure|persist.sys.usb.config)=' $ramdisk|grep -E '(prop|default)$'`;do
        echo mod $prop_file
        sed -i 's/ro.secure=1/ro.secure=0/g' $prop_file
        sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $prop_file
        sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $prop_file
        sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $prop_file
    done
    AIK-Linux/repackimg.sh
    bash -x ./resign.sh AIK-Linux/image-new.img $image
    mv AIK-Linux/image-new.img $imagedirname/$imagepartname-repack.img
    AIK-Linux/cleanup.sh
done
