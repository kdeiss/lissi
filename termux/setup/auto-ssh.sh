#!/data/data/com.termux/files/usr/bin/sh

LOG="/data/data/com.termux/files/opt/lissi/fc/LISSI.log"
echo "`date` INF startup $0" >>$LOG
termux-wake-lock
sshd
