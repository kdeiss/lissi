#! /bin/bash
# by k.deiss@it-userdesk.de
# send keycode via adb
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.17.03.23 move to subfolder
# V 0.0.4.23.03.23 adapt to termux


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
ARG1=$1
LOG="$WPATH/LISSI.log"
TMP="$WPATH/`basename $0.tmp`"

##############script detection#########################
LOCKFILE=$WPATH/$(basename $0).lck

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


KEYCODE=""
if [ -f "$ARGFILE" ] ;then
    echo "`date` INF `basename $0` using keycode from $ARGFILE!" |tee -a $LOG
    source $ARGFILE
else
    echo "`date` ERR `basename $0` can't find $ARGFILE!" |tee -a $LOG
    rm -f $LOCKFILE
    exit 1
fi


# check which device is requested
if [ -z $DEVICE ] ;then
    source $PLAYERCFG
    if [ -z $DEVICE ] ;then
	echo "`date` ERR `basename $0` device not specified!" |tee -a $LOG
	rm -f $LOCKFILE
	exit 2
    fi
fi
echo "DEVICE=$DEVICE"|tee -a $LOG


if [ -z $KEYCODE ] ;then
    echo "`date` ERR `basename $0` KEYCODE not specified!"
    exit 3
fi

# find out whether screen is powered off
# this code has to be checked for older devices!
adb -s $DEVICE shell dumpsys input_method | grep "mInteractive=false" > ./null
if [ $? -eq 0 ];then
    echo "`date` INF `basename $0` screen is off!"|tee -a $LOG
    if [ ! $KEYCODE -eq 26 ] ;then
	adb -s $DEVICE shell input keyevent 26
    fi
fi


echo "`date` INF `basename $0` sending KEYCODE $KEYCODE"
adb -s $DEVICE shell input keyevent $KEYCODE

rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
exit 0

