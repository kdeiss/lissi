WPATH=`dirname $0`
PLAYERCFG="$WPATH/DEVICE.cfg"
TMPFNAME="$WPATH/`basename $0.txt`"

ARG1=$1
DEVICE=$2




LOG="$WPATH/LISSI.log"

EXTLOCKFILE="$WPATH/WETTER.sh.lck"
touch $EXTLOCKFILE

termux-tts-speak "Es ist `date +"%-H Uhr und %-M Minuten"`. Hallo Malick!. Wie geht es dir? Geht es Mama auch gut?. Wie geht es denn Uschi?. Hast Du so viele Salzstangen gegessen?"

rm -f  $EXTLOCKFILE
exit 0

STOPSEM="$WPATH/STOP.sem"
    if [ -f $STOPSEM ];then
	echo "`date` WAR found $STOPSEM - stop speechoutput"|tee -a $LOG
	rm -f $STOPSEM
	clean_exit
	exit 0
    fi
