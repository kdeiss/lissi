#! /bin/bash
# display webpage
# by k.deiss@it-userdesk.de
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.17.03.23 move to subfolder
# V 0.0.4.20.03.23 clean_exit
# V 0.0.5.23.03.23 adapt to termux

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
ARG1=$1
LOG="$WPATH/LISSI.log"
TMP="/tmp/`basename $0.tmp`"
TMP="$WPATH/`basename $0.tmp`"


##############script detection#########################
LOCKFILE=$WPATH/$(basename $0).lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -o cmd -p $SPID |grep `basename $0` >> ./null
    if [ $? -eq 0 ] ; then
        echo "`date` INF `basename $0` already running"
        exit 1
    else
        echo "`date` WAR `basename $0` has lockfile but is not running!" >> $LOG
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

function clean_exit
{
rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
echo "`date` INF $0 done."|tee -a $LOG
}

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
    echo "`date` WAR `basename $0` duplicate files found for $ARG1.sh.cfg!" |tee -a $LOG
fi


PIC=""
URL=""
if [ -f "$ARGFILE" ] ;then
    # here should be implemented some security steps, maybe not to use source!
    echo "`date` INF `basename $0` using url from $ARGFILE!" |tee -a $LOG
    source $ARGFILE
else
    #echo "URL=\"http://it-userdesk.de/dl/mediathek/radio/notyetspecified.mp3\"" > $ARG1.cfg
    echo "`date` ERR `basename $0` can't find file <$ARGFILE>!" |tee -a $LOG
    clean_exit
    exit 1
fi

# check which device is requested
if [ -z $DEVICE ] ;then
    #if devicename is not specified inside $0.cfg we load devicename from PLAYER.cfg
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR `basename $0` device not specified!" |tee -a $LOG
	clean_exit
	exit 3
    fi
fi

echo "DEVICE=$DEVICE"|tee -a $LOG

if [ -z $URL ] ;then
    echo "`date` ERR `basename $0` URL not specified!" |tee -a $LOG
    clean_exit
    exit 3
else
    # if PIC is not explicitely defined in .cfg we use the standard PIC
    if [ -z $PIC ] ; then
	PIC=$WEBURL
    fi
fi

echo "URL=$URL"|tee -a $LOG
echo "PIC=$PIC"|tee -a $LOG


# find out whether screen is powered off
# this has to be checked for older devices!
adb -s $DEVICE shell dumpsys input_method | grep "mInteractive=false"
if [ $? -eq 0 ];then
    echo "`date` INF `basename $0` Screen is off!"|tee -a $LOG
    adb -s $DEVICE shell input keyevent 26
fi


# if we have screen lock (daydream) send back key
WHF=`adb -s $DEVICE shell dumpsys window windows | grep -E 'mCurrentFocus'`
echo "`date` INF `basename $0` app in foreground is: $WHF"|tee -a $LOG
echo $WHF | grep "dream" >./null
# we send this only if daydream has focus
if [ $? -eq 0 ]; then
    adb -s $DEVICE shell input keyevent 4
    sleep 0.1
fi

# call the web page
# sonderlocke NIL (stop background music and exit


if [ ! " $PIC" == " NIL" ] ; then
    #show html page - very primitive solution but its just adb....
    echo "`date` INF `basename $0` try to call webpage $PIC."|tee -a $LOG
    adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC
else
    echo "`date` INF `basename $0` no webcall, just stop background."|tee -a $LOG
    echo "`date` INF `basename $0` try to call vlc and exit."|tee -a $LOG
    adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL
    clean_exit    
    exit 0
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
if [ $rst -eq 1 ];then
    # seems that a stream is already playing we exit
    echo "`date` INF `basename $0` Stream is already playing skip recall."|tee -a $LOG
    clean_exit    
    exit 0
fi


# start playing the background stream with vlc directly
echo "`date` INF try to call vlc."|tee -a $LOG
adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL

clean_exit
exit 0
