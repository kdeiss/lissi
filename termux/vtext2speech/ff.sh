#! /bin/bash
# 
# by k.deiss@it-userdesk.de
# retrieve time and battery state, output to speech-tts
# V 0.0.1.22.02.23

# require pkg jq 

#set -x

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

ARG1=$1
DEVICE=$2

LOG="$WPATH/LISSI.log"
TMP="/$WPATH/`basename $0.tmp`"


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


# change to the working directory
cd $WPATH

echo "`date` INF startup $0"|tee -a $LOG

EXTLOCKFILE="$WPATH/NEWS-NRW.sh.lck"

if [ -f "$EXTLOCKFILE" ];then
    echo "`date` WAR found $EXTLOCKFILE - speechoutput not possible"|tee -a $LOG
    clean_exit
    exit 1
fi


EXTLOCKFILE="$WPATH/NEWS-NATIONAL.sh.lck"
if [ -f "$EXTLOCKFILE" ];then
    echo "`date` WAR found $EXTLOCKFILE - speechoutput not possible"|tee -a $LOG
    clean_exit
    exit 1
fi


EXTLOCKFILE="$WPATH/WETTER.sh.lck"
if [ -f "$EXTLOCKFILE" ];then
    echo "`date` WAR found $EXTLOCKFILE - speechoutput not possible"|tee -a $LOG
    clean_exit
    exit 1
fi

termux-tts-speak "Es ist `date +"%-H Uhr und %-M Minuten"`. Die Batterie ist zu `termux-battery-status | jq ".percentage"` Prozent geladen"

clean_exit
exit 0
