#!/data/data/com.termux/files/usr/bin/bash
# by k.deiss@it-userdesk.de
# setup lissi on termux (part 2)
# V 0.0.1.15.02.23
# V 0.0.2.24.03.23 kd bugfix

# url: https://raw.githubusercontent.com/kdeiss/lissi/master/termux/setup/setup_lissi.sh


WPATH=`dirname $0`
TMP="/$WPATH/`basename $0.tmp`"
TERMUXDIR="/data/data/com.termux/files"
ASTART="$TERMUXDIR/home/.termux/boot"
LISSIDIR="$TERMUXDIR/opt/lissi"
FLOWDIR="$TERMUXDIR/home/.node-red"
LOG="$TERMUXDIR/lissi_installer.log"


function clean_exit
{
rm -f $TMP
rm -f ./null
rm -f $LOCKFILE
echo "`date` INF $0 done."|tee -a $LOG
}

function prepare_tmxver
{
mkdir `dirname $LISSIDIR` 2> ./null
mkdir $LISSIDIR 2> ./null
mkdir "$LISSIDIR/fc" 2> ./null
cd $LISSIDIR
if [ $? -eq 0 ];then
    echo "`date` INF created required directories." | tee -a $LOG
else
    echo "`date` ERR could not create  required directories. - exit"
    clean_exit
    exit 1
fi
}

function gitti
{
    echo "`date` INF git pull to retrieve lissi core files." | tee -a $LOG
    mkdir `dirname $LISSIDIR` 2> ./null
    cd `dirname $LISSIDIR`
    if [ ! $? -eq 0 ];then
	echo "`date` ERR did not find required directory (`dirname $LISSIDIR`). - exit"
	clean_exit
	exit 1
    fi

    git clone https://github.com/kdeiss/lissi
    if [ ! $? -eq 0 ];then
	echo "`date` ERR git clone returned fail. - exit"
	clean_exit
	exit 1
    fi

    touch "$LISSIDIR/autoadb/autoadb.txt"
    touch "$LISSIDIR/fc/DEVICE.cfg"
    touch "$LISSIDIR/fc/LOCAL_DEVICES.cfg"
    touch "$LISSIDIR/fc/STATIC_DEVICES.cfg"
}


function create_autostart
{
mkdir $ASTART 2> ./null
cp $LISSIDIR/termux/setup/auto*.sh $ASTART 
if [ $? -eq 0 ];then
    echo "`date` INF Autostart created" | tee -a $LOG
else
    echo "`date` ERR could not create autostart - exit" | tee -a $LOG
    clean_exit
    exit 1
fi
}

function install_pkgs
{
echo "`date` INF Installing required packages" | tee -a $LOG
apt update
apt upgrade -y
apt install -y git openssl-tool openssh python coreutils nano nodejs wget jq mc termux-api openssh android-tools html2text | tee -a $LOG
echo "`date` INF package installation done!" | tee -a $LOG
}


function install_nr
{
echo "`date` INF Installing nodered" | tee -a $LOG
npm i -g --unsafe-perm node-red | tee -a $LOG
npm install node-red-dashboard | tee -a $LOG
echo "`date` INF nodered installation done!" | tee -a $LOG
}

function config_nr
{
# the actual flows.json should be available now
echo "`date` INF configuring nodered" | tee -a $LOG
cp $LISSIDIR/nodered/flows.json $FLOWDIR
if [ $? -eq 0 ];then
    echo "`date` INF actual flows.json copied" | tee -a $LOG
else
    echo "`date` ERR could not copy flows.json - exit" | tee -a $LOG
    clean_exit
    exit 1
fi
}

function info2user
{
echo "###################################################"
echo "In case of trouble check the installer log at $LOG"
echo "SSH daemon will start next boot automatically."
echo "Your username is >`whoami`<."
echo "To use it from external ssh client set password (just call passwd on commandline)."
echo "Please reboot the system. Check the logs at $LISSIDIR/fc/LISSI.log"
echo "###################################################"
}


echo "`date` INF startup $0" | tee -a $LOG
install_pkgs
gitti
prepare_tmxver
create_autostart
install_nr
config_nr
clean_exit
info2user
exit 0
