#! /bin/bash
# PLAYER.sh
# by k.deiss@it-userdesk.de
# play url with vld via adb 
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location


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
else
    PIC=${URL//.m3u/.html}
fi

# stop  instance of vlc / smarttube
# am force-stop com.teamsmart.videomanager.tv
# am force-stop org.videolan.vlc

# show html page - very uggly solution but its just adb
# echo "SHOW HTML"
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC

# send power key twice (in case we are in daydream)
# this is only necessary if we have screen lock
# echo "SEND POWERKEY"
# adb -s $DEVICE shell input keyevent 26
# sleep 0.5
# echo "SEND POWERKEY"
# adb -s $DEVICE shell input keyevent 26
# sleep 0.5

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

# show home screen
# adb -s $DEVICE shell input keyevent 3
# sleep 0.5

# start playing with android.intent
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $URL

# start with vlc directly
sleep 1
 echo "CALL VLC"
 adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL

#echo "SHOW HTML"
#adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC

#echo "KILL IPTVEXTREME"
#adb -s $DEVICE shell am force-stop com.pecana.iptvextreme
sleep 1
#echo "CALL IPTVEXTREME"
#adb -s $DEVICE shell am start -n com.pecana.iptvextreme/.VideoActivityExo $URL
