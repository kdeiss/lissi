#! /bin/bash
# PLAYER.sh
# by k.deiss@it-userdesk.de
# play media (audio) url with vlc via adb 
# ARG1 = media to play
# ARG2 = deviceID (overwrite default device)
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.17.03.23 move to subfolder
# V 0.0.4.20.03.23 clean_exit / deviceID as parameter / logging of adb calls
# V 0.0.5.23.03.23 adapt to termux
# V 0.0.6.29.03.23 introducing tmpl files in media folder


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

ARG1=$1
DEVICE=$2

LOG="$WPATH/LISSI.log"
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


echo "`date` startup $0 with ARG1:>$ARG1< ARG2:>$DEVICE<"|tee -a $LOG
echo "PLAYERCFG=$PLAYERCFG"|tee -a $LOG
echo "ARG1=$ARG1"|tee -a $LOG

# change to the working directory, search station file load it
cd $WPATH

ARGFILE=""
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

# if the configfile was not found we look for a templatefile
# this mechanism was introduced to give possibiltiy to use git for updates
# whilst user have already individual configurations

if [ ! -f "$ARGFILE" ] ;then
    echo "`date` INF `basename $0` could not find configuration file for $ARG1 - searching now template." |tee -a $LOG
    find $WPATH -name $ARG1.sh.cfg.tmpl>$TMP

    let ctr=0
    while read line
    do
	TMPLFILE=$line
	let ctr=$ctr+1
    done<$TMP

    if [ $ctr -gt 1 ];then
	echo "`date` WAR `basename $0` duplicate files found for $ARG1.sh.cfg.tmpl!" |tee -a $LOG
    fi

    #if we found template we copy it to a regular cfg file
    if [ -f "$TMPLFILE" ] ;then
	ARGFILE=${TMPLFILE//.sh.cfg.tmpl/.sh.cfg}	
	cp "$TMPLFILE" "$ARGFILE"
	echo "`date` INF First run detected for channel $ARG1. $ARGFILE created from Template." |tee -a $LOG
    fi
fi



PIC=""
URL=""
if [ -f "$ARGFILE" ] ;then
    # here should be implemented some security steps, maybe not to use source!
    echo "`date` INF `basename $0` using url from $ARGFILE!" |tee -a $LOG
    source $ARGFILE
else
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
	exit 2
    fi
fi

echo "DEVICE=$DEVICE"|tee -a $LOG

if [ -z $URL ] ;then
    echo "`date` ERR `basename $0` URL not specified!"
    clean_exit
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
echo "`date` INF `basename $0` try to call station logo $PIC."|tee -a $LOG
adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC &>>$LOG


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
    echo "`date` INF `basename $0` playback detected - going to stop this."|tee -a $LOG
    adb -s $DEVICE shell input keyevent 85 &>>$LOG
    sleep 0.1
fi


# find out whether screen is powered off
# this has to be checked for older devices!
adb -s $DEVICE shell dumpsys input_method | grep "mInteractive=false"
if [ $? -eq 0 ];then
    echo "`date` INF `basename $0` Screen is off!"|tee -a $LOG
    adb -s $DEVICE shell input keyevent 26 &>>$LOG
fi


# if we have screen lock (daydream) send back key
WHF=`adb -s $DEVICE shell dumpsys window windows | grep -E 'mCurrentFocus'`
echo "`date` INF `basename $0` app in foreground is: $WHF"|tee -a $LOG
echo $WHF | grep "dream" >./null
# we send this only if daydream has focus
if [ $? -eq 0 ]; then
    adb -s $DEVICE shell input keyevent 4 &>>$LOG
    sleep 0.1
fi


# start playing with android.intent
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $URL

# start playing with vlc directly
echo "`date` INF try to call vlc."|tee -a $LOG
adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL &>>$LOG


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
	    echo "`date` INF `basename $0` media playback detected."|tee -a $LOG
	    let i=$max
	    let rst=1
	    break
	fi
    done < $TMP
    if [ $i -lt $max ] ; then
	sleep 15
	echo "`date` INF `basename $0` retry to start stream again ($i)"|tee -a $LOG
	adb -s $DEVICE shell am start -n org.videolan.vlc/.StartActivity $URL &>>$LOG
    fi
done


if [ $rst -eq 0 ] ;then
    echo "`date` WAR `basename $0` no media playback from this stream!"|tee -a $LOG
fi

# echo "SHOW HTML"
# adb -s $DEVICE shell am start -a android.intent.action.VIEW -d $PIC

clean_exit
exit 0
