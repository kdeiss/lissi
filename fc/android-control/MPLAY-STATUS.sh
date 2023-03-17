#! /bin/bash
# by k.deiss@it-userdesk.de
# check state of mediaplayer
# V 0.0.1.16.3.23 logging yes/no

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMP="$WPATH/`basename $0.txt`"
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


# check whether a stream is playing
let rst=0
adb -s $DEVICE shell dumpsys media_session | grep "PlaybackState">$TMP
while read line
do
    echo $line | grep "state=3" > ./null
    if [ $? -eq 0 ];then
        let rst=1
        break
    fi
done < $TMP

rm -f $TMP
rm -f ./null

if [ $rst -eq 0 ];then
	echo "No MediaPlayBack."
	if [ $DEBOUT -gt 0 ];then
	    echo "`date` INF No MediaPlayBack." >> $LOG
	fi
else
	echo "MediaPlayBack active"
	if [ $DEBOUT -gt 0 ];then
	    	echo "`date` INF MediaPlayBack active" >> $LOG
	fi
fi
