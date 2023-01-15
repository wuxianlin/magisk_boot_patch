#!/usr/bin/env sh


get_args() {
    python3 avbtool.py info_image --image $1>image_info

    args=''

    algorithm=`cat image_info|grep ^Algorithm:`
    algorithm=${algorithm##* }
    args=$args' --algorithm '${algorithm}
    if [[ $algorithm =~ .*_RSA4096 ]]; then
        args=$args' --key testkey_rsa4096.pem'
    elif [[ $algorithm =~ .*_RSA2048 ]]; then
        args=$args' --key testkey_rsa2048.pem'
    elif [[ $algorithm =~ .*_RSA8192 ]]; then
        args=$args' --key testkey_rsa8192.pem'
    else
        echo error
    fi
    hash_algorithm=`cat image_info|grep 'Hash Algorithm:'`
    args=$args' --hash_algorithm '${hash_algorithm##* }
    rollback_index=`cat image_info|grep '^Rollback Index:'`
    args=$args' --rollback_index '${rollback_index##* }
    rollback_index_location=`cat image_info|grep '^Rollback Index Location:'`
    args=$args' --rollback_index_location '${rollback_index_location##* }
    cat image_info|sed 's/ -> /:/g'|grep Prop: > props
    for prop in `cat props|sed 's/Prop://g'|sed "s/'//g"`;do
        args=$args' --prop '${prop}
    done

    rm image_info props

    echo $args
}


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

for bootimage in `find boot -name boot.img -o -name init_boot.img`;do
    bootdirname=`dirname $bootimage`
    bootpartname=`basename $bootimage`
    bootpartname=${bootpartname%%.*}
    magiskbootname=magisk-$MAGISK_VER.img
    adb push $bootimage /data/local/tmp/boot.img
    adb shell KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT KEEPVERITY=$KEEPVERITY sh /data/local/tmp/boot_patch.sh /data/local/tmp/boot.img
    adb pull /data/local/tmp/new-boot.img $bootdirname/$magiskbootname
    python3 avbtool.py erase_footer --image $bootdirname/$magiskbootname
    python3 avbtool.py add_hash_footer --image $bootdirname/$magiskbootname --partition_size $(wc -c < $bootimage) --partition_name $bootpartname $(get_args $bootimage)
    adb shell /data/local/tmp/magiskboot cleanup
    adb shell ls /data/local/tmp/
    adb shell rm /data/local/tmp/*
    echo stock boot
    python3 avbtool.py info_image  --image $bootimage
    echo magisk boot
    python3 avbtool.py info_image  --image $bootdirname/$magiskbootname
done
