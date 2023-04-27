#! /bin/bash
# 
# by k.deiss@it-userdesk.de
# retrieve time and battery state, output to speech-tts
# V 0.0.1.26.04.23


#set -x

WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
MODNAME="`basename $0`"
TMPFNAME="$WPATH/$MODNAME.tmp"

#LOG="$WPATH/torch.log"
LOG="$WPATH/null"


##############script detection#########################
LOCKFILE=$WPATH/$MODNAME.lck

if [ -f $LOCKFILE ] ; then
    SPID=`cat $LOCKFILE`
    ps -o cmd -p $SPID |grep `basename $0` >> ./null
    if [ $? -eq 0 ] ; then
        echo "`date` INF $MODNAME already running" >> $LOG
        exit 1
    else
        echo "`date` WAR $MODNAME has lockfile but is not running!" >> $LOG
    fi
fi


del_lock()
{
    echo "`date` $MODNAME WARNING external signal caught, exiting" >> $LOG
    rm -f $LOCKFILE
}

trap "del_lock ; exit 1" 2 9 15
echo $$ > $LOCKFILE

##############script detection#########################

function clean_exit
{
#rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
echo "`date` INF $MODNAME done.<br>"|tee -a $LOG
}


# change to the working directory
cd $WPATH

echo "">$LOG
echo "`date` INF startup $MODNAME<br>"|tee -a $LOG

if [ -f $TMPFNAME ];then
    cmd=`cat $TMPFNAME`
    echo "`date` INF State of torch was: $cmd<br>" |tee -a $LOG
    if [ " $cmd" == " on" ];then
	termux-torch off
	echo "off" >$TMPFNAME
    else
	termux-torch on
	echo "on" >$TMPFNAME
    fi
else
    echo "`date` INF will generate new $TMPFNAME<br>" |tee -a $LOG
    termux-torch on
    echo "on" >$TMPFNAME
fi

clean_exit
exit 0
