#!/bin/bash
touch autoadb/autoadb.txt
touch fc/DEVICE.cfg
touch fc/LOCAL_DEVICES.cfg
touch fc/STATIC_DEVICES.cfg


for a in `find .`
do
    chown nodered:nodered $a -v
done

for d in `find . -type d`
do
    chmod 770 $d -v
done 


for f in `find "fc/media" -type f`
do
    ls -la $f
    chmod 660 $f -v
    ls -la $f
done 
