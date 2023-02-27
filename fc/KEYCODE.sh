#! /bin/bash
# by k.deiss@it-userdesk.de
# play url with adb 
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

if [ -f $0.cfg ] ;then
    source $0.cfg
else
    echo "KEYCODE=" > $0.cfg
    echo "`date` ERR can't find $0.cfg!"
    exit 1
fi

if [ -z $DEVICE ] ;then
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR device not specified!"
	exit 2
    fi
fi

if [ -z $KEYCODE ] ;then
    echo "`date` ERR KEYCODE not specified!"
    exit 2
fi

#adb -s $DEVICE shell input keyevent $KEYCODE
adb -s $DEVICE shell input keyevent $KEYCODE
