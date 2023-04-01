#!/data/data/com.termux/files/usr/bin/bash
# by k.deiss@it-userdesk.de
# setup lissi on termux (part 2)
# V 0.0.1.15.02.23
# V 0.0.2.24.03.23 kd bugfix

# url: https://raw.githubusercontent.com/kdeiss/lissi/master/termux/setup/setup_lissi.sh


WPATH=`dirname $0`
if [ " $WPATH" == " ." ] ; then
    WPATH=`pwd`
fi
TMP="/$WPATH/`basename $0.tmp`"
TERMUXDIR="/data/data/com.termux/files"
ASTART="$TERMUXDIR/home/.termux/boot"
LISSIDIR="$TERMUXDIR/opt/lissi"
FLOWDIR="$TERMUXDIR/home/.node-red"
LOG="$TERMUXDIR/lissi_installer.log"
NULLFN="$WPATH/null"
CALLER=`basename $0`



function clean_exit
{
rm -f $TMP
rm -f $NULLFN
rm -f $LOCKFILE
echo "`date` INF $0 done."|tee -a $LOG
}

function prepare_tmxver
{
mkdir `dirname $LISSIDIR` 2> $NULLFN
mkdir $LISSIDIR 2> $NULLFN
mkdir "$LISSIDIR/fc" 2> $NULLFN
cd $LISSIDIR
if [ $? -eq 0 ];then
    echo "`date` INF created required directories." | tee -a $LOG
else
    echo "`date` ERR could not create  required directories. - exit"
    clean_exit
    exit 1
fi
cd $WPATH
}

function gitti
{
    echo "`date` INF git pull to retrieve lissi core files." | tee -a $LOG
    mkdir `dirname $LISSIDIR` 2> $NULLFN
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
    cd $WPATH
}


function create_autostart
{
mkdir $ASTART 2> $NULLFN
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
apt install -o DPkg::Options::=--force-confdef -y git openssl-tool openssh python coreutils nano nodejs wget jq mc termux-api openssh android-tools html2text | tee -a $LOG
echo "`date` INF package installation done!" | tee -a $LOG
}


function install_nr
{
cd "$TERMUXDIR/home"
echo "`date` INF Installing node-red" | tee -a $LOG
npm i -g --unsafe-perm node-red | tee -a $LOG
mkdir $FLOWDIR 2> $NULLFN
cd "$TERMUXDIR/home/.node-red"
echo "`date` INF Installing node-red-dashboard" | tee -a $LOG
npm install node-red-dashboard | tee -a $LOG
echo "`date` INF nodered installation done!" | tee -a $LOG
cd $WPATH
}

function config_nr
{
mkdir $FLOWDIR 2> $NULLFN
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
echo "To use ssh from external device set a password! (just type passwd on commandline)"
echo "Please reboot the system. Check the logs at $LISSIDIR/fc/LISSI.log"
echo "###################################################"
}

function patch_flow
{
OUT="./flows.json"
mkdir $FLOWDIR 2> $NULLFN
cp $LISSIDIR/nodered/flows.json $OUT
if [ ! $? -eq 0 ];then
    echo "`date` ERR could not patch flows.json - exit" | tee -a $LOG
fi

sed -i -e "s/\"\/opt\/lissi/\"\/data\/data\/com.termux\/files\/opt\/lissi/g" $OUT
if [ $? -eq 0 ];then
    echo "`date` INF actual flows.json patched" | tee -a $LOG
else
    echo "`date` ERR could not patch flows.json - exit" | tee -a $LOG
    clean_exit
    exit 11
fi

cp $OUT $FLOWDIR
if [ $? -eq 0 ];then
    echo "`date` INF actual flows.json copied" | tee -a $LOG
else
    echo "`date` ERR could not copy flows.json - exit" | tee -a $LOG
    clean_exit
    exit 1
fi

rm -f $OUT

}


function patch_nr
{
OUT="$TERMUXDIR/usr/lib/node_modules/node-red/red.js"

if [ ! -f $OUT ];then
    echo "`date` ERR could not patch node-red.test - exit" | tee -a $LOG
fi

cp $OUT $OUT.sik

sed -i -e "s/\#!\/usr\/bin\/env node/\#!\/data\/data\/com.termux\/files\/usr\/bin\/env node/g" $OUT
if [ $? -eq 0 ];then
    echo "`date` INF actual node-red patched for termux." | tee -a $LOG
else
    echo "`date` ERR could not patch node-red." | tee -a $LOG
    clean_exit
    exit 12
fi
}



echo "`date` INF startup $0" | tee -a $LOG


echo $CALLER
if [ " $CALLER" == " patch_nr.sh" ] ; then
    # if code is called by patch_nr.sh we just patch the flows.json
    echo "`date` INF will only patch flows.json."|tee -a $LOG
    patch_flow
    clean_exit
    echo "`date` INF pls restart to run the moded flows.json"|tee -a $LOG
    exit 0
fi

# if code is called by setup_lissi.sh we install
install_pkgs
gitti
prepare_tmxver
create_autostart
install_nr
#config_nr
patch_flow
patch_nr
info2user
echo "Creating new password for user `whoami`."
passwd

exit 0
