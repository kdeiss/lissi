#!/bin/bash

# k.deiss@it-userdesk.de
# Delete old files (here the lastseen files to enforce a link grab)
# V.01.04.04.23 initial commit
# V.02.24.04.23 AGE changed

BASENAME="radio-net-scraper"

#BASEPATH=`pwd`
BASEPATH="/opt/lissi/scraper/radio.net"
GITPATH="/opt/lissi/"

BNVARIANT="$BASENAME"

LOG="$BASEPATH/${BNVARIANT}.log"
LOGDEB="$BASEPATH/DEB_${BNVARIANT}.log"
TMPF="/tmp/${BNVARIANT}.tmp"
TMPF1="/tmp/${BNVARIANT}1.tmp"
TMPF2="/tmp/${BNVARIANT}2.tmp"
NULL=./null
OUTDIR="RadioLib"

HTMLQ="/root/.cargo/bin/htmlq"
EMPTYLINK="NO_RESULT"


AGE="+1440" 		# 1440 minutes = 1 day, files older than this deleted immediately
AGE="+720"
AGE="+2880"
AGE="+4320"
AGE="+5760"
HTMLAGE="+43200" 	# 30 days


function rmold-lastseen()
{
echo "`find . -type f |grep ".lastseen" |wc -l` lastseen files total." | tee -a $LOG
let MAXDELETIONS=15
OIFS="$IFS"
IFS=$'\n'
let ctr=0
let actr=0

# delete files older than defined
for dir in $(find . -mmin $AGE -type f -name "*.lastseen"); do
    if [ $ctr -lt $MAXDELETIONS ];then
	echo "`date` INF deleting old .lastseen file $dir" | tee -a $LOG
	rm -f "$dir"
	if [ $? -eq 0 ] ; then
	    let ctr=$ctr+1
	else
	    echo "`date` ERR can't remove $dir" | tee -a $LOG
	fi
    fi
let actr=$actr+1
done
echo "`date` INF $ctr .lastseen files with age $AGE removed (Total $actr)" | tee -a $LOG
IFS=$OIFS
}


function rmold-html()
{
echo "`find ./html -type f |grep ".html" |wc -l` html files total." | tee -a $LOG

OIFS="$IFS"
IFS=$'\n'
let ctr=0
let actr=0

# delete files older than defined
for dir in $(find ./html -mmin $HTMLAGE -type f -name "*.html"); do
	echo "`date` INF deleting old html file $dir" | tee -a $LOG
	rm -f "$dir"
	if [ $? -eq 0 ] ; then
	    let ctr=$ctr+1
	else
	    echo "`date` ERR can't remove $dir" | tee -a $LOG
	fi
	let actr=$actr+1
done
echo "`date` INF $ctr html files with age $HTMLAGE removed (Total $actr)" | tee -a $LOG
IFS=$OIFS
}

echo "`date` INF startup $0" | tee -a $LOG
cd $BASEPATH
rmold-lastseen
rmold-html
echo "`date` INF exit $0" | tee -a $LOG
echo "" >> $LOG
rm -f $NULL
