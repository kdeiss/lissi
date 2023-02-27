Entstand im Zusammenspiel mit scrcpy (Fernsteuerung von Androd devicen)

Dieses Tool wird auf einem raspi installiert wo das Handy angesteckt wird.
Automatisiert wird ein Proxy gestartet, so dass aus dem Netz auf dieses lokal angeschlossene device zugegriffen werden kann.

Ab V04 kann ein cfg File angelegt werden.
Die dort definierten ANDROS führen beim Start eine Aktion durch.
Zur Zeit 1 = ADB Over IP



################################################
# CRON
################CRON############################
* * * * * /opt/lissi/autoadb/autoadb


################CRON############################
# Installation
################CRON############################

apt-get install adb
#cp ./10-usb.rules.0 /etc/udev/rules.d/10-usb.rules
./INIT_AUTOADB

