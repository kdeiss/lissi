#!/bin/bash
# k.deiss@it-userdesk.de
# mirror folder to web-resource
# V.01.16.04.23
# V.02.25.04.23 only one instance

BASENAME="radio-net-scraper"
BASEPATH="/opt/lissi/scraper/radio.net"
#BASEPATH="/opt/temp"
BNVARIANT="$BASENAME"
#LOG="$BASEPATH/${BNVARIANT}.log"
LOG="$BASEPATH/DEB_${BNVARIANT}.log"
TEMP="/tmp/upload-html.tmp"

# get username and password
# put a copy of this variables into file ~/.upload.txt
USER="user"                      		#Your username
PASS="password"                  		#Your password
HOST="meinhost.de"	            		#Keep just the address
LCD="/opt/lissi/scraper/radio.net/html"		#Your local directory
RCD="/httpdocs/dl/mediathek/radio.net"       	#FTP server directory


##############script detection#########################
LOCKFILE=/tmp/$(basename $0).lck
#[ -f $LOCKFILE ] && { echo "`date` INF $0 already running" >> $LOG; exit 1; }
#[ -f $LOCKFILE ] && { exit 1; }

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

mirror --continue --delete --verbose -R -n -p --no-umask $LCD $RCD
#mirror --continue --delete -R -n -p --no-umask $LCD $RCD
exit
EOF
}

echo "`date` INF Startup $0" >> $LOG
upload &> $TEMP
echo "`date` INF `wc -l $TEMP` lines processed" >> $LOG
rm -f $LOCKFILE
echo "`date` INF Stop $0" >> $LOG
