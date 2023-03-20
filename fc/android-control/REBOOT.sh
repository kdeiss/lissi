#! /bin/bash
# by k.deiss@it-userdesk.de
# reboot android device
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.20.03.23 adapted to new architecture

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
LOG="$WPATH/LISSI.log"
TMP="/tmp/`basename $0.tmp`"
DEVICE=$1
ACTION_AFTER_REBOOT="/opt/lissi/fc/RPLAYER.sh wdr2 $DEVICE"

cd $WPATH

echo "`date` INF startup $0"|tee -a $LOG

if [ -z $DEVICE ] ;then
    echo "`date` WAR device not given as argument, using defalt device"|tee -a $LOG
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR device not specified!" |tee -a $LOG
	exit 2
    fi
fi

echo "`date` INF device selected: $DEVICE "|tee -a $LOG
#exit 0

adb -s $DEVICE shell reboot &>> $LOG
sleep 60
let ctr=0
echo "`date` INF Device $DEVICE rebooting!"|tee -a $LOG
while [ $ctr -lt 120 ];do
    let ctr=$ctr+1
    adb devices | grep $DEVICE > ./null
    if [ $? -eq 0 ];then
	echo "`date` INF Device $DEVICE back after $ctr tries"|tee -a $LOG
	cd ..
	sleep 10
	echo "`date` INF running ACTION_AFTER_REBOOT: $ACTION_AFTER_REBOOT"|tee -a $LOG
	$ACTION_AFTER_REBOOT
	sleep 1
	$ACTION_AFTER_REBOOT
	break
    fi
    sleep 1
done

rm -f ./null
