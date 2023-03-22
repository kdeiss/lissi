#! /bin/bash
# by k.deiss@it-userdesk.de
# get adb device status
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location
# V 0.0.3.16.3.23 logging yes/no

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
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



adb -s $DEVICE shell getprop > $TMPFNAME
#if [ $DEBOUT -gt 0 ];then
#    echo "`date` INF $RST">> $LOG
#fi

grep $TMPFNAME -e "product.name" > $TMPFNAME.1
grep $TMPFNAME -e "ipaddress" >> $TMPFNAME.1
grep $TMPFNAME -e "hostname" >> $TMPFNAME.1
grep $TMPFNAME -e "d.version.release]" >> $TMPFNAME.1
IPA=`adb -s $DEVICE shell ip addr show wlan0 | grep "inet "` 
echo $IPA >> $TMPFNAME.1

dos2unix $TMPFNAME.1 > ./null

echo -n "" >$TMPFNAME
while read line
do
    echo "$line<br>" >>$TMPFNAME
done < $TMPFNAME.1

#unix2dos $TMPFNAME.1 > ./null
cat $TMPFNAME

if [ $DEBOUT -gt 0 ];then
    echo "`date` INF deviceinfo">> $LOG
    cat $TMPFNAME >> $LOG
fi


rm -f $TMPFNAME
rm -f $TMPFNAME.1
rm -f ./null
