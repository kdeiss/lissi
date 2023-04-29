#!/bin/bash
# k.deiss@it-userdesk.de
# mirror folder to web-resource
# requires lftp
# V.01.16.04.23
# V.02.25.04.23 only one instance


WPATH=`dirname $0`
MODNAME="`basename $0`"
TIMESTAMP_DAY=`date "+%Y-%m-%d"`
LOG="$WPATH/$TIMESTAMP_DAY.log"
NULL="$WPATH/null"


# get username and password
# put a copy of this variables into file ~/.upload.txt
USER="user"                      		# Your username
PASS="password"                  		# Your password
HOST="meinhost.de"	            		# Keep just the address
RCD="/httpdocs/dl/snap/cam01"	       		# FTP server directory
LCD="/sdcard/DCIM/Camera"			# Your local directory

#echo $LCD
#exit

##############script detection#########################
LOCKFILE=$WPATH/$(basename $0).lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -e | grep $SPID >> /dev/null
    if [ $? -eq 0 ] ; then
        # echo "`date` INF $0 already running"
        exit 1
    else
        echo "`date` WAR $0 has lockfile but is not running!" >> $LOG
    fi
fi


del_lock()
{
    echo "`date` $0 WARNING external signal caught, exiting" >> $LOG
    rm -f $LOCKFILE
}

trap "del_lock ; exit 1" 2 9 15
echo $$ > $LOCKFILE
##############script detection#########################


if [ -f ~/.upload.txt ] ; then
    echo "`date` INF reading config from ~/.upload.txt" >> $LOG
    source ~/.upload.txt
else
    echo "`date` INF no config ~/.upload.txt!" >> $LOG
    exit 1
fi

function upload
{
lftp -u "$USER","$PASS" "$HOST" <<EOF
lcd $LCD
cd $RCD
mirror --continue --delete --verbose -R -n -p --no-umask $LCD $RCD >> $LOG
exit
EOF
}

echo "`date` INF Startup $0" >> $LOG
upload >> $LOG
rm -f $LOCKFILE
echo "`date` INF Stop $0" >> $LOG

