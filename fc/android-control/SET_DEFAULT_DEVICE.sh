#! /bin/bash
# by k.deiss@it-userdesk.de
# set the default device (DEVICE.cfg)
# V 0.0.1.17.03.23


WPATH=`dirname $0`
DEVICECFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
LOG="$WPATH/android_status.log"
let DEBOUT=1 # log yes/no

cd $WPATH

DEVID=$1
if [ -z $DEVID ] ;then
    echo "`date` ERR missing deviceID call: $0 devID">> $LOG
    exit 1
else
    echo "DEVICE=\"$DEVID\"" > $DEVICECFG
    if [ $? -eq 0 ] ;then
	echo "`date` INF `basename $0` changed global devID to $DEVID">> $LOG
	exit 0
    else
	echo "`date` ERR `basename $0` can't change deviceID $0 devID">> $LOG
	exit 1
    fi
fi
