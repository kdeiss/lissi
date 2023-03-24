#! /bin/bash
# VTEXT.sh
# by k.deiss@it-userdesk.de
# retrieve teletext page and read it with tts-speak
# V 0.0.1.15.02.23

#set -x

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

ARG1=$1
DEVICE=$2

LOG="$WPATH/LISSI.log"
TMP="/$WPATH/`basename $0.tmp`"


##############script detection#########################
LOCKFILE=$WPATH/$(basename $0).lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -o cmd -p $SPID |grep `basename $0` >> ./null
    if [ $? -eq 0 ] ; then
        echo "`date` INF `basename $0` already running"
        exit 1
    else
        echo "`date` WAR `basename $0` has lockfile but is not running!" >> $LOG
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

function clean_exit
{
rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
echo "`date` INF $0 done."|tee -a $LOG
}


echo "`date` startup $0 with ARG1:>$ARG1< ARG2:>$DEVICE<"|tee -a $LOG
echo "PLAYERCFG=$PLAYERCFG"|tee -a $LOG
echo "ARG1=$ARG1"|tee -a $LOG

# change to the working directory, search station file load it
cd $WPATH

if [ -z $ARG1 ] ; then
    ARG1=100
fi

OUT="Seite $ARG1 geladen um `date +"%-H Uhr %-M"`."
cd $WPATH

rm -f $WPATH/$ARG1.asc
rm -f $WPATH/$ARG1.html
wget https://mobiltext.wdr.de/$ARG1.html -O $WPATH/$ARG1.html

if [ -f $WPATH/$ARG1.html ];then
    echo "`date` INF `basename $0` converting html to text" >> $LOG
    html2text -ascii -nobs $WPATH/$ARG1.html >> $WPATH/$ARG1.asc
else
    echo "ERR retrieving page $ARG1"
    exit 1
fi

rm -f $WPATH/$ARG1.html

let ctr=0
while read lin
do
    let ctr=$ctr+1
    if [ $ctr -gt 39 ] && [ $ctr -lt 59 ];then
	lin=${lin//\"a/ae}
	lin=${lin//\"u/ue}
	lin=${lin//\"o/oe}
	lin=${lin//\"U/ue}
	lin=${lin//\"A/Ae}
	lin=${lin//\"O/Oe}
	lin=${lin//\*/}
	lin=${lin//\#/ }
	
    	if [ $ctr -eq 40 ];then
    	    lin="${lin}."
    	fi
    	
    	echo "<$lin>"
	
	if [ ! -z "$OUT" ] ;then
	    OUT="$OUT $lin"
	else
	    OUT="${lin}."
	fi
    fi
done < $WPATH/$ARG1.asc
#done < cat $WPATH/$ARG.txt

OUT=${OUT//- /}
echo $OUT

termux-tts-speak $OUT

clean_exit
exit 0

