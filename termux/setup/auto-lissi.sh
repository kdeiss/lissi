#!/data/data/com.termux/files/usr/bin/sh
DIR2CLEAN="/data/data/com.termux/files/opt/lissi/termux/vtext2speech"
LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"

echo "`date` INF startup Lissi system running on termux" >$LOG

cd "$DIR2CLEAN"
ls *.lck
rm -f $DIR2CLEAN/*.lck
sleep 15
adb connect localhost
echo "`date` INF android devices: `adb devices` " >>$LOG
