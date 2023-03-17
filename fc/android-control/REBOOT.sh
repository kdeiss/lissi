#! /bin/bash
# by k.deiss@it-userdesk.de
# play url with adb 
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

if [ -z $DEVICE ] ;then
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR device not specified!"
	exit 2
    fi
fi

adb -s $DEVICE shell reboot
sleep 60
let ctr=0
echo "`date` INF Device $DEVICE rebooting!">> $0.log
while [ $ctr -lt 120 ];do
    let ctr=$ctr+1
    adb devices | grep $DEVICE > ./null
    if [ $? -eq 0 ];then
	echo "`date` INF Device $DEVICE back after $ctr tries" >> $0.log
	echo "`date` INF Device $DEVICE back after $ctr tries"
	cd ..
	sleep 10
	echo "`date` INF Start radiostation!" >> $0.log
	echo "`date` INF Start radiostation!"
	/opt/lissi/fc/wdr2.sh
	break
    fi
    sleep 1
done

rm -f ./null
