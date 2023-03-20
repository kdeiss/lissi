# sicherungskopie nach nodered einspielen
# nach einem pull ausfuehren

cp /home/nodered/.node-red/flows.json.01 /home/nodered/.node-red/flows.json.02
cp /home/nodered/.node-red/flows.json /home/nodered/.node-red/flows.json.01

node-red-stop
cat ./flows.json > /home/nodered/.node-red/flows.json
node-red-start

