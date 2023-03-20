#! /bin/bash
# sicherungskopie nodered anlegen
# vor commit -a ausführen!
node-red-stop
cp /home/nodered/.node-red/flows.json .
node-red-start
