#!/data/data/com.termux/files/usr/bin/sh
DIR2CLEAN="/data/data/com.termux/files/opt/lissi/termux/vtext2speech"
LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"

cp $LOG.4 $LOG.5
cp $LOG.3 $LOG.4
cp $LOG.2 $LOG.3
cp $LOG.1 $LOG.2
cp $LOG $LOG.1


echo "`date` INF startup $0 (Lissi system running on termux)" >$LOG

cd "$DIR2CLEAN"
ls *.lck
rm -f $DIR2CLEAN/*.lck

#sleep 15
#adb connect localhost
#echo "`date` INF android devices: `adb devices` " >>$LOG
#echo "`date` INF exit $0." >>$LOG

/data/data/com.termux/files/opt/lissi/00_condev &
