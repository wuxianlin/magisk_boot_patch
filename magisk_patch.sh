#!/usr/bin/env sh

CPU_ABI=$1
KEEPFORCEENCRYPT=$2
KEEPVERITY=$3

if [ ! -d magisk ];then
    echo "magisk not found"
    exit 1
fi

if [ ! -d magisk/lib/$CPU_ABI ];then
    echo "magisk for cpu_abi:"$CPU_ABI" not found"
    exit 1
fi

eval $(cat magisk/assets/util_functions.sh|grep MAGISK_VER=)
echo $MAGISK_VER

adb wait-for-device

echo device found

adb push magisk/lib/$CPU_ABI

adb push magisk/lib/x86_64/libmagiskboot.so /data/local/tmp/magiskboot
adb push magisk/lib/$CPU_ABI/libmagiskinit.so /data/local/tmp/magiskinit

if [ "$CPU_ABI" = "arm64-v8a" ] || [ "$CPU_ABI" = "armeabi-v7a" ];then
    if [ "$CPU_ABI" = "arm64-v8a" ]; then
        adb push magisk/lib/arm64-v8a/libmagisk64.so /data/local/tmp/magisk64
    fi
    adb push magisk/lib/armeabi-v7a/libmagisk32.so /data/local/tmp/magisk32
elif [ "$CPU_ABI" = "x86_64" ] || [ "$CPU_ABI" = "x86" ];then
    if [ "$CPU_ABI" = "x86_64" ]; then
        adb push magisk/lib/x86_64/libmagisk64.so /data/local/tmp/magisk64
    fi
    adb push magisk/lib/x86/libmagisk32.so /data/local/tmp/magisk32
else
    echo "cpu_abi:"$CPU_ABI" may not be supported"
fi

adb push magisk/assets/boot_patch.sh /data/local/tmp/
adb shell chmod 755 /data/local/tmp/boot_patch.sh
adb push magisk/assets/util_functions.sh /data/local/tmp/

for bootimage in `find imgs -name boot.img -o -name init_boot.img`;do
    bootdirname=`dirname $bootimage`
    bootpartname=`basename $bootimage`
    bootpartname=${bootpartname%%.*}
    magiskbootname=magisk-$bootpartname-$MAGISK_VER.img
    adb push $bootimage /data/local/tmp/boot.img
    adb shell KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT KEEPVERITY=$KEEPVERITY sh /data/local/tmp/boot_patch.sh /data/local/tmp/boot.img
    adb pull /data/local/tmp/new-boot.img $bootdirname/$magiskbootname
    python3 avbtool.py erase_footer --image $bootdirname/$magiskbootname
    bash resign.sh $bootdirname/$magiskbootname $bootimage
    adb shell /data/local/tmp/magiskboot cleanup
    adb shell ls /data/local/tmp/
    adb shell rm /data/local/tmp/*
    echo stock boot
    python3 avbtool.py info_image  --image $bootimage
    echo magisk boot
    python3 avbtool.py info_image  --image $bootdirname/$magiskbootname
done
