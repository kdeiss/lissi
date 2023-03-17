#! /bin/bash
# by k.deiss@it-userdesk.de
# find locally atached android devices
# returns a list of these devices (called from nodered to populate dropdown list)
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location


WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
LOCAL_DEVICES=$WPATH/LOCAL_DEVICES.cfg
STATIC_DEVICES=$WPATH/STATIC_DEVICES.cfg
LOG="$WPATH/android_status.log"
let DEBOUT=1 # log yes/no


cd $WPATH
touch $STATIC_DEVICES


adb devices > $TMPFNAME
if [ ! $? -eq 0 ] ;then
    echo "`date` ERR can't access $TMPFNAME">> $LOG
    exit 1
fi


echo -n > $LOCAL_DEVICES
if [ ! $? -eq 0 ] ;then
    echo "`date` ERR can't access $LOCAL_DEVICES">> $LOG
    exit 2
fi


let ctr=0
while read line
do
    if [ $ctr -gt 0 ] ;then
	if [ ! -z "$line" ] ; then
	    lbegin=`echo $line | cut -f 1 -d " "`
	    cat $STATIC_DEVICES | grep "$lbegin" > ./null
	    if [ ! $? -eq 0 ];then
		# this device is not member of static devices!
		echo "`date` INF found LOCAL_DEVICE: $lbegin">> $LOG
		echo "$lbegin,device-$ctr">> $LOCAL_DEVICES
	    fi
	fi
    fi
    let ctr=$ctr+1
done < $TMPFNAME

rm -f $TMPFNAME
cat $LOCAL_DEVICES
cat $STATIC_DEVICES

