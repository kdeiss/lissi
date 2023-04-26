#!/bin/bash
# k.deiss@it-userdesk.de
# mirror folder to web-resource
# V.01.16.04.23 initial commit
# V.02.26.04.23 adapt m3u dir


#get username and password
USER="user"                      		#Your username
PASS="password"                  		#Your password
HOST="meinhost.de"	            		#Keep just the address
LCD="/opt/lissi/scraper/radio.net/m3u"		#Your local directory
RCD="/httpdocs/dl/mediathek/radio.net.m3u"     	#FTP server directory

if [ -f ~/.upload.txt ] ; then
    echo "`date` INF reading config from ~/.upload.txt"
    source ~/.upload.txt
else
    echo "`date` INF no config ~/.upload.txt!"
    exit 1
fi

echo "`date` INF Create mirror $LCD => $HOST / $RCD"
lftp -u "$USER","$PASS" "$HOST" <<EOF
lcd $LCD
cd $RCD
mirror --continue --delete --verbose -R $LCD $RCD
exit
EOF


