#!/data/data/com.termux/files/usr/bin/bash
# 
# take picture via termux:api and upload this to a web server
# by k.deiss@it-userdesk.de
# V 0.0.1.28.04.23
# V 0.0.2.29.04.23 uploader

WPATH=`dirname $0`
MODNAME="`basename $0`"
TMPFNAME="$WPATH/$MODNAME.tmp"

TIMESTAMP_DAY=`date "+%Y-%m-%d"`
TIMESTAMP_NOW=`date "+%Y%m%d_%H%M%S"`
LOG="$WPATH/$TIMESTAMP_DAY.log"
NULL="$WPATH/null"


CAM_ID=0
SNAP_TARGET="$WPATH/Camera"
PICUPLOAD=0

del_lock()
{
    echo "`date` $MODNAME WARNING external signal caught, exiting" >> $LOG
    clean_exit
}

trap "del_lock ; exit 1" 2 9 15

function clean_exit
{
rm -f $TMPFNAME
rm -f $NULL
echo "`date` INF $MODNAME done.">> $LOG
echo "">> $LOG
}


# change to the working directory
cd $WPATH
echo "`date` INF startup $MODNAME">> $LOG

if [ -f $0.cfg ];then
    source $0.cfg
fi


termux-camera-photo -c $CAM_ID $SNAP_TARGET/LissiSnap_${TIMESTAMP_NOW}.jpg &>> $LOG
if [ ! $? -eq 0 ];then
    echo "`date` ERR can't take snap!">> $LOG
    clean_exit
    exit 1
fi

if [ $PICUPLOAD -eq 1 ] ; then
    $WPATH/upload-pics.sh
fi

clean_exit
exit

