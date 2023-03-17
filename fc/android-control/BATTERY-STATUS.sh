#! /bin/bash
# by k.deiss@it-userdesk.de
# check state of android battery
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.16.3.23 logging yes/no

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
LOG="$WPATH/android_status.log"
let DEBOUT=0 # log yes/no

cd $WPATH

if [ -z $DEVICE ] ;then
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR device not specified!"
	exit 2
    fi
fi


#BDATA=`adb -s $DEVICE shell dumpsys battery`
#echo $BDATA | grep level

RST=`adb -s $DEVICE shell dumpsys battery | grep level | cut -f 2 -d ":" | head -1`
if [ $DEBOUT -gt 0 ];then
    echo "`date` INF $RST">> $LOG
fi
echo $RST
