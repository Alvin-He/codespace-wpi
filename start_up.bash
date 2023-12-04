#! /bin/bash

##########
## ROOT ##
##########
#https://stackoverflow.com/a/29969243
if [ $UID -eq 0 ]; then
    service ssh stop
    service ssh start


  exec su "system" "$0" -- "$@"
fi
############
## system ##
############
cd /home/system/vscode
./bin/code serve-web --cli-data-dir ./bin/cli --server-data-dir ./server_data --user-data-dir ./user_data --extensions-dir ./extensions --host 0.0.0.0 --port 8000 --without-connection-token --accept-server-license-terms