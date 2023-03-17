#! /bin/bash
# PLAYER.sh
# by k.deiss@it-userdesk.de
# play url with vld via adb 
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
ARG1=$1
LOG="$WPATH/LISSI.log"
TMP="/tmp/`basename $0.tmp`"


##############script detection#########################
LOCKFILE=/tmp/$(basename $0).lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -o cmd -p $SPID |grep `basename $0` >> ./null
    if [ $? -eq 0 ] ; then
        echo "`date` INF $0 already running"
        exit 1
    else
        echo "`date` WAR $0 has lockfile but is not running!" >> $LOG
    fi
fi


del_lock()
{
    echo "`date` $0 WARNING external signal caught, exiting" >> $LOG
    rm -f $LOCKFILE
}

trap "del_lock ; exit 1" 2 9 15
echo $$ > $LOCKFILE

##############script detection#########################


echo "`date` startup $0 with ARG1 $ARG1" |tee -a $LOG
echo "PLAYERCFG=$PLAYERCFG"|tee -a $LOG
echo "ARG1=$ARG1"|tee -a $LOG

# change to the working directory, search station file load it
cd $WPATH

#ARGFILE=`find $WPATH -name $ARG1.sh.cfg`
# if there are 2 or more files we always choose the first!
find $WPATH -name $ARG1.sh.cfg>$TMP

let ctr=0
while read line
do
    ARGFILE=$line
    let ctr=$ctr+1
done<$TMP

if [ $ctr -gt 1 ];then
    echo "`date` WAR duplicate files found for $ARG1.sh.cfg!" |tee -a $LOG
fi


PIC=""
URL=""
if [ -f "$ARGFILE" ] ;then
    # here should be implemented some security steps, maybe not to use source!
    echo "`date` INF using url from $ARGFILE!" |tee -a $LOG
    source $ARGFILE
else
    #echo "URL=\"http://it-userdesk.de/dl/mediathek/radio/notyetspecified.mp3\"" > $ARG1.cfg
    echo "`date` ERR can't find $ARGFILE!" |tee -a $LOG
    rm -f $LOCKFILE
    exit 1
fi


# check which device is requested
if [ -z $DEVICE ] ;then
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR device not specified!" |tee -a $LOG
	rm -f $LOCKFILE
	exit 2
    fi
fi

echo "DEVICE=$DEVICE"|tee -a $LOG

if [ -z $URL ] ;then
    echo "`date` ERR URL not specified!"
    rm -f $LOCKFILE
    exit 3
else
    # if PIC is not explicitely defined in .cfg we use the standard PIC
    if [ -z $PIC ] ; then
	PIC=${URL//.m3u/.html}
    fi
fi

echo "URL=$URL"|tee -a $LOG
echo "PIC=$PIC"|tee -a $LOG


# stop  instance of vlc / smarttube
# am force-stop com.teamsmart.videomanager.tv
# am force-stop org.videolan.vlc


#show html page - very primitive solution but its just adb....
echo "`date` INF try to call station logo $PIC."|tee -a $LOG
adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC


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

if [ $rst -eq 1 ];then
    # seems that a stream is playing we stop it
    echo "`date` INF playback detected - going to stop this."|tee -a $LOG
    adb -s $DEVICE shell input keyevent 85
    sleep 0.1
fi


# find out whether screen is powered off
# this has to be checked for older devices!
adb -s $DEVICE shell dumpsys input_method | grep "mInteractive=false"
if [ $? -eq 0 ];then
    echo "`date` INF Screen is off!"|tee -a $LOG
    adb -s $DEVICE shell input keyevent 26
fi


# if we have screen lock (daydream) send back key
WHF=`adb -s $DEVICE shell dumpsys window windows | grep -E 'mCurrentFocus'`
echo "`date` INF prog in foreground: $WHF"|tee -a $LOG
echo $WHF | grep "dream" >./null
# we send this only if daydream has focus
if [ $? -eq 0 ]; then
    adb -s $DEVICE shell input keyevent 4
    sleep 0.1
fi


# start playing with android.intent
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $URL

# start playing with vlc directly
echo "`date` INF try to call vlc."|tee -a $LOG
adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL


# checkwhether there is playback
let i=0
let max=5
let rst=0
sleep 5
while [ $i -lt $max ]
do
    let i=$i+1
    adb -s $DEVICE shell dumpsys media_session | grep "PlaybackState">$TMP
    while read line
    do
	echo $line | grep "state=3" > ./null
	if [ $? -eq 0 ];then
	    echo "`date` INF media playback detected."|tee -a $LOG
	    let i=$max
	    let rst=1
	    break
	fi
    done < $TMP
    if [ $i -lt $max ] ; then
	sleep 15
	echo "`date` INF retry to start stream again ($i)"|tee -a $LOG
	adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL
    fi
done


if [ $rst -eq 0 ] ;then
    echo "`date` WAR no media playback from this stream!"|tee -a $LOG
fi

# echo "SHOW HTML"
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC

rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
exit 0
