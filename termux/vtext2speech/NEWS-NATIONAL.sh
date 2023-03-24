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

#set -x

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

ARG1=$1
DEVICE=$2

LOG="$WPATH/LISSI.log"
TMP="/$WPATH/`basename $0.tmp`"
STOPSEM="$WPATH/STOP.sem"

rm -f $STOPSEM
echo "" >> $LOG
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


echo "`date` startup $0"|tee -a $LOG

# change to the working directory, search station file load it
cd $WPATH

LISTE="151 152 153 154 155 156 157 158 159"
#LISTE="111 112 113 114 115 116 117 118 119 120 181 182"
#LISTE="111 181 182"

EXTLOCKFILE="$WPATH/ff.sh.lck"
if [ -f "$EXTLOCKFILE" ];then
    echo "`date` WAR found $EXTLOCKFILE - speechoutput not possible"|tee -a $LOG
    clean_exit
    exit 1
fi


EXTLOCKFILE="$WPATH/NEWS-NRW.sh.lck"
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


for i in $LISTE
do
    echo $i
    $WPATH/VTEXT.sh $i
    if [ -f $STOPSEM ];then
	echo "`date` WAR found $STOPSEM - stop speechoutput"|tee -a $LOG
	rm -f $STOPSEM
	clean_exit
	exit 0
    fi
done
echo "" >> $LOG
clean_exit
