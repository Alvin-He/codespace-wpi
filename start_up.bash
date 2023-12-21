#! /bin/bash

k_comp_year=2023


e_MESSAGES=(
  #0
  "You should never see this message, you harddrive is corrupted if you do."
  #1
  "Some mounts or symlinks are broken, check if Docker volumes are attached and mounted." 

)
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

flag_boot_proceed=true

#error handling

e_handel_boot_fail() {
  if [[ $flag_boot_proceed != true ]]; then 
    echo "ERROR: ${e_MESSAGES[1]}"
    echo "ERROR: FAILED TO BOOT DUE TO PREVIOUS ERROR, exiting with code $1"
    exit "$1"
  fi
}

#check mounts
mount_targets_to_check=( 
  "/home/system/wpilib/$k_comp_year/roborio"
)
is_mounts_valid() {
  for path in ${mount_targets_to_check[@]}; do
    # checks if symlinks exist, then checks if they are broken or not
    if [[(! -L "$path") || ( $(readlink -q "$path") && ($? -eq 0)) ]]; then 
      flag_boot_proceed=false
      return
    fi
    echo "checked path $path"
  done
  flag_boot_proceed=true
}

# main boot sequence
is_mounts_valid
e_handel_boot_fail 1

cd /home/system/vscode
./bin/code serve-web --cli-data-dir ./bin/cli --server-data-dir ./server_data --user-data-dir ./user_data --extensions-dir ./extensions --host 0.0.0.0 --port 8000 --without-connection-token --accept-server-license-terms