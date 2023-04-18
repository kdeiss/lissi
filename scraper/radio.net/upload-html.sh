#!/bin/bash
# k.deiss@it-userdesk.de
# mirror folder to web-resource
# V.01.16.04.23



#get username and password
USER="user"                      		#Your username
PASS="password"                  		#Your password
HOST="meinhost.de"	            		#Keep just the address
LCD="/opt/lissi/scraper/radio.net/html"		#Your local directory
RCD="/httpdocs/dl/mediathek/radio.net"       	#FTP server directory

if [ -f ~/.upload.txt ] ; then
    echo "reading config from ~/.upload.txt"
    source ~/.upload.txt
else
    echo "no config ~/.upload.txt!"
    exit 1
fi

lftp -u "$USER","$PASS" "$HOST" <<EOF
lcd $LCD
cd $RCD

mirror --continue --delete --verbose -R -n -p --no-umask $LCD $RCD
exit
EOF


