#! /bin/bash
# by k.deiss@it-userdesk.de
# Node Red wrapper
# V 0.0.1.15.02.23
# V 0.0.2.20.02.23 flexible location

ARG1=$1
WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"
LOG="$WPATH/`basename $0.log`"


# echo "`date` TMPFNAME=$TMPFNAME"
# echo "`date` PLAYERCFG=$PLAYERCFG"
# echo "`date` ARG1=$ARG1"

echo "`date` TMPFNAME=$TMPFNAME" >> $LOG
echo "`date` PLAYERCFG=$PLAYERCFG" >> $LOG
echo "`date` ARG1=$ARG1" >> $LOG

if  [ -z $ARG1 ] ;then
    echo "`date` ERR ARG1 empty!" >> $LOG
    exit 1
fi



if  [ -f $WPATH/$ARG1.sh ] ;then
    echo "Startup $WPATH/$ARG1.sh"
    $WPATH/$ARG1.sh >> $LOG
    exit 0
else 
    echo "`date` ERR $WPATH/$ARG1.sh not found!" >> $LOG
    exit 2
fi
