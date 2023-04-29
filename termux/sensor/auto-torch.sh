#!/data/data/com.termux/files/usr/bin/bash
# 
# by k.deiss@it-userdesk.de
# switch on torch if light sensor is higher than defined in SENSOR_THRESHOLD
# e.g. bathroom opening door will automatically on torch and off it after SENSOR_WAIT
# V 0.0.1.26.04.23
# V 0.0.2.28.04.23	external cfg file


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
MODNAME="`basename $0`"
TMPFNAME="$WPATH/$MODNAME.tmp"

LOG="$WPATH/auto-torch.log"
NULL="$WPATH/null"

# you can edit these vars in $0.cfg
SENSOR_NAME="CM36686 Light"	# name of sensor
SENSOR_DIFF=1			# max to diff to previous value
SENSOR_THRESHOLD=4		# threshold
SENSOR_WAIT=3			# wait n minutes to revert the sensor action
SENSOR_PLAY_RADIO=1		# play something if sensor is acting - note play will be continuely 
SENSOR_PLAY_RADIO_CMD="/data/data/com.termux/files/opt/lissi/fc/WEBPAGE.sh WEB_pl_wdr2" # what to play - here a website with background radio 
SENSOR_TAKE_SNAP=0		# take a snap
SENSOR_TAKE_SNAP_CMD="/data/data/com.termux/files/opt/lissi/termux/takesnap/take-snap.sh" # path to snapper


del_lock()
{
    echo "`date` $MODNAME WARNING external signal caught, exiting" >> $LOG
    clean_exit
}

trap "del_lock ; exit 1" 2 9 15




function clean_exit
{
termux-sensor -c 2>$NULL
rm -f $TMPFNAME
rm -f $NULL
echo "`date` INF $MODNAME done.">> $LOG
}

function do_torch_on
{
    echo "`date` INF Switch torch to on!" >> $LOG

    termux-torch on
    echo "on" >$TMPFNAME


    if [ $SENSOR_TAKE_SNAP -eq 1 ];then
	echo "`date` INF Take snap!" >> $LOG
	$SENSOR_TAKE_SNAP_CMD
	sleep 1
	$SENSOR_TAKE_SNAP_CMD
	cd $WPATH
    fi


    if [ $SENSOR_PLAY_RADIO -eq 1 ];then
	echo "`date` INF Play radio!" >> $LOG
	$SENSOR_PLAY_RADIO_CMD &>>$LOG
	sleep 15
	$SENSOR_PLAY_RADIO_CMD &>>$LOG
	sleep 15
	$SENSOR_PLAY_RADIO_CMD &>>$LOG
	cd $WPATH
    fi

}




function do_torch_off
{
    echo "`date` INF Switch torch to off!" >> $LOG
    termux-torch off
    echo "off" >$TMPFNAME
}


# change to the working directory
cd $WPATH

rm -f $LOG
echo "`date` INF startup $MODNAME">> $LOG

termux-sensor -c 2>$NULL
termux-sensor -l | grep "$SENSOR_NAME">$NULL
if [ ! $? -eq 0 ];then
    echo "`date` ERR Sensor $SENSOR_NAME not available!">> $LOG
    clean_exit
    exit 1
fi

echo "`date` INF using sensor $SENSOR_NAME.">> $LOG
rm -f $TMPFNAME

let ctr=0
while true ; do
    if [ -f $TMPFNAME ];then
	cmd=`cat $TMPFNAME`
	# echo "`date` INF State of torch is: $cmd" >> $LOG
	if [ " $cmd" == " on" ];then
	    if [ $ctr -gt $SENSOR_WAIT ];then
		do_torch_off
		let ctr=0
		sleep 1
	    else
		echo "`date` INF waiting to switch off torch(${ctr}/${SENSOR_WAIT})." >> $LOG
		let ctr=$ctr+1
		sleep 60
		continue
	    fi
	fi
    fi

    if [ -f $0.cfg ];then
	source $0.cfg
    fi

    light=$(termux-sensor -n 1 -s "$SENSOR_NAME" | sed '4q;d')
    if [ $light -gt $SENSOR_THRESHOLD ] ; then
	echo "`date` INF sensor light: $light.">> $LOG
	do_torch_on
    fi


    if [ -f $0.sem ] ; then
	rm -f $0.sem
	clean_exit
	echo "`date` INF Found semaphore - exit now!" >> $LOG
	exit 0
    fi

    if [ -f $0.restart ] ; then
	rm -f $0.restart
	clean_exit
	echo "`date` INF Found restart semaphore - restarting now!" >> $LOG
	sleep 1
	$0 &
	exit 0
    fi

sleep 0.1
done

clean_exit
exit
