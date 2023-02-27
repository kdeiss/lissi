#! /bin/bash
# by k.deiss@it-userdesk.de
# play youtube url with smarttube via adb 
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# set -x

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"


if [ -f $0.cfg ] ;then
    source $0.cfg
else
    echo "URL=\"\"" > $0.cfg
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

if [ -z $URL ] ;then
    echo "`date` ERR URL not specified!"
    exit 2
fi

# if we have no screen lock just send back key
WHF=`adb -s $DEVICE shell dumpsys window windows | grep -E 'mCurrentFocus'`
echo $WHF | grep "dream"
# we send this only if daydream has focus
if [ $? -eq 0 ]; then
    echo "SEND BACK KEY"
    adb -s $DEVICE shell input keyevent 4
else
    echo "DAYDREAM HAS NO FOCUS"
fi

adb -s $DEVICE shell am start -n com.teamsmart.videomanager.tv/com.liskovsoft.smartyoutubetv2.tv.ui.main.SplashActivity "$URL"
