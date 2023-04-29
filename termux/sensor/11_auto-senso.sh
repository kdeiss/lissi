#!/data/data/com.termux/files/usr/bin/sh

# copy this file to $ASTART (autostart) if you want to run it after reboot
TERMUXDIR="/data/data/com.termux/files"
ASTART="$TERMUXDIR/home/.termux/boot"


export HISTCONTROL=ignoreboth
export PATH=/data/data/com.termux/files/usr/bin
export LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so


LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"

echo "`date` INF startup $0" >>$LOG

$TERMUXDIR/opt/lissi/termux/sensor/auto-torch.sh
rst=$?
echo "`date` INF Exit code for auto-torch: $rst" >>$LOG

