#! /bin/bash
# 
# by k.deiss@it-userdesk.de
# switch on torch if light sensor is higher than defined in SENSOR_THRESHOLD
# e.g. bathroom opening door 
# V 0.0.1.26.04.23


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
MODNAME="`basename $0`"
TMPFNAME="$WPATH/$MODNAME.tmp"

LOG="$WPATH/auto-torch.log"
NULL="$WPATH/null"


SENSOR_NAME="CM36686 Light"	# name of sensor
SENSOR_DIFF=1			# max to diff to previous value
SENSOR_THRESHOLD=4		# threshold

##############script detection#########################
LOCKFILE=$WPATH/$MODNAME.lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -o cmd -p $SPID |grep `basename $0` >> ./null
    if [ $? -eq 0 ] ; then
        echo "`date` INF $MODNAME already running" >> $LOG
        exit 1
    else
        echo "`date` WAR $MODNAME has lockfile but is not running!" >> $LOG
    fi
fi


del_lock()
{
    echo "`date` $MODNAME WARNING external signal caught, exiting" >> $LOG
    #rm -f $LOCKFILE
    clean_exit
}

trap "del_lock ; exit 1" 2 9 15
echo $$ > $LOCKFILE

##############script detection#########################

function clean_exit
{
termux-sensor -c 2>$NULL
rm -f $TMPFNAME
rm -f $NULL
rm -f $LOCKFILE
echo "`date` INF $MODNAME done."|tee -a $LOG
}

function do_torch_on
{
    echo "`date` INF Switch torch to on" |tee -a $LOG
    termux-torch on
    echo "on" >$TMPFNAME
    /data/data/com.termux/files/opt/lissi/fc/WEBPAGE.sh WEB_pl_wdr2
}

function do_torch_off
{
    echo "`date` INF Switch torch to off" |tee -a $LOG
    termux-torch off
    echo "off" >$TMPFNAME
    $TMPFNAME
}


# change to the working directory
cd $WPATH

echo "">$LOG
echo "`date` INF startup $MODNAME<br>"|tee -a $LOG

termux-sensor -c 2>$NULL
termux-sensor -l | grep "$SENSOR_NAME">$NULL
if [ ! $? -eq 0 ];then
    echo "`date` ERR Sensor $SENSOR_NAME not available!"|tee -a $LOG
    clean_exit
    exit 1
fi

echo "`date` INF using sensor $SENSOR_NAME."|tee -a $LOG

let ctr=0
while true ; do
    if [ -f $TMPFNAME ];then
	cmd=`cat $TMPFNAME`
	echo "`date` INF State of torch is: $cmd" |tee -a $LOG
	if [ " $cmd" == " on" ];then
	    rst=$(find . -newermt '-15 minutes' -name $TMPFNAME 2>$NULL)
	    if [ ! -z $rst ] ;then
		do_torch_off
		sleep 5
	    else
		echo "`date` INF waiting to switch off torch." |tee -a $LOG
		sleep 5
		continue
	    fi
	fi
    fi

    light=$(termux-sensor -n 1 -s "$SENSOR_NAME" | sed '4q;d')
    if [ $light -gt $SENSOR_THRESHOLD ] ; then
	echo "`date` INF sensor light: $light."|tee -a $LOG
	do_torch_on
    fi
    let ctr=$ctr+1

    if [ -f $0.sem ] ; then
	rm -f $0.sem
	clean_exit
	echo "`date` INF Found semaphore - exit now!" |tee -a $LOG
	exit 0
    fi

    if [ -f $0.restart ] ; then
	rm -f $0.restart
	clean_exit
	echo "`date` INF Found restart semaphore - restarting now!" |tee -a $LOG
	$0 &
	exit 0
    fi
done

clean_exit
exit
