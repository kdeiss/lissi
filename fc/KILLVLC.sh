#! /bin/bash
# PLAYER.sh
# by k.deiss@it-userdesk.de
# kill vlc via adb 
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

# stop  instance of vlc / smarttube
# am force-stop com.teamsmart.videomanager.tv
adb -s $DEVICE shell am force-stop org.videolan.vlc

exit 0
