#!/data/data/com.termux/files/usr/bin/sh
# copy this file to $ASTART
TERMUXDIR="/data/data/com.termux/files"
ASTART="$TERMUXDIR/home/.termux/boot"

LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"
echo "`date` INF startup $0" >>$LOG
echo "`date` INF NOTE: Modul $0 will log into /data/data/com.termux/files/opt/lissi/termux/sensor" >>$LOG
/data/data/com.termux/files/opt/lissi/termux/sensor/auto-torch.sh
