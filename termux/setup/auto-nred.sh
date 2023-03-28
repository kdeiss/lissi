#!/data/data/com.termux/files/usr/bin/bash

export HISTCONTROL=ignoreboth
export PATH=/data/data/com.termux/files/usr/bin
export LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so

LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"

cp $LOG.2 $LOG.3
cp $LOG.1 $LOG.2
cp $LOG $LOG.1


echo "`date` INF startup $0" >>$LOG

let RST=0
let ctr=0
while [ $RST -eq 0 ];do
    /data/data/com.termux/files/usr/bin/node-red &>> $LOG
    sleep 15
    pgrep node
    if [ $? -eq 0 ];then
	echo "`date` INF nodered running!($ctr)" >>$LOG
	let RST=1
	break
    fi

    sleep 15
    pgrep node
    if [ $? -eq 0 ];then
	echo "`date` INF nodered running!($ctr)" >>$LOG
	let RST=1
	break
    fi

    let ctr=$ctr+1
    if [ $ctr -gt 10 ];then
	echo "`date` INF can't start nodered!" >>$LOG
	let RST=2
	break
    fi    
done

echo "`date` INF done $0" >>$LOG
exit 0
