#!/bin/bash

MYDIR=`dirname $0`

ROM_ZIP=rom.zip
OUT=out

mkdir -p $OUT

axel -n 10 -o $ROM_ZIP $ROM_URL

if [ ! -f $ROM_ZIP ];then
    echo download failed!
    exit 1
fi

unzip -q -o $ROM_ZIP -d $OUT/rom

rm $ROM_ZIP

for zipfile in `find $OUT/rom -name *.zip`;do
    zippath=$(dirname $zipfile)
    zipname=$(basename $zipfile)
    zipfoldername=${zipname%.zip}
    unzip -q -o $zipfile -d $zippath/$zipfoldername
    rm $zipfile
done

for payloadbin in `find $OUT/rom -name payload.bin`;do
    payloadpath=$(dirname $payloadbin)
    python3 $MYDIR/payload_dumper/payload_dumper.py $payloadbin --out $payloadpath
    rm $payloadbin
done

mv 

mkdir -p $OUT/img

for img in `find $OUT/rom -name boot.img -o -name vbmeta.img`;do
    imgpath=$(dirname $img)
    imgpath=${imgpath#$OUT/rom*}
    mkdir $OUT/img/$imgpath
    mv $img $OUT/img/$imgpath/
done



