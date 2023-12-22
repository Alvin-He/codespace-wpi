#! /bin/bash

source /home/system/wpi_codespace/.env
source /home/system/wpi_codespace/config.conf

e_MESSAGES=(
  #0
  "You should never see this message, you harddrive is corrupted if you do."
  #1
  "Failed due to previous error when the script is running in root."
  #2
  "Insufficient permissions, please run this script with root priviliages."
  #3
  "Some mounts or symlinks are broken/corrupted, check if Docker volumes are attached and mounted correctly." 

)

# internal ARGs:
#   $1: falg_boot_proceed from previous session 

#flags
flag_boot_proceed=true
[[ ! -z $1 ]] && flag_boot_proceed=$1

#error handling

# $1-error code; $2-does program terminate
e_handel_boot_fail() {
  if [[ $flag_boot_proceed != true ]]; then 
    echo "ERROR: ${e_MESSAGES[$1]}"
    if [[ $2 = false ]]; then return; fi
    echo "ERROR: FAILED TO BOOT DUE TO PREVIOUS ERROR, exiting with code $1"
    exit "$1"
  fi
}

#check mounts
mount_targets_to_check=( 
  "/home/system/wpilib/$COMP_YEAR/roborio"
  "/home/system/.gradle/caches"
  "/home/system/.gradle/permwrapper"
)
try_fix_mounts() {
  #mounted, but missing cache directories/incorrect perms
  # chown system /mnt/shared_caches/ $(ls "/mnt/shared_caches/" | grep -w "No such file or directory") && $? -ne 0
  if [[ ! -d "/mnt/shared_caches/" ]]; then return; fi
  chmod 777 /mnt/shared_caches/

  # attempt to make the cache directories
  mkdir -p -m 0777 /mnt/shared_caches/roborio
  mkdir -p -m 0777 /mnt/shared_caches/gradle/caches
  mkdir -p -m 0777 /mnt/shared_caches/gradle/permwrapper
}
# $1-try fixing mounts
is_mounts_valid() {
  for path in ${mount_targets_to_check[@]}; do
    # checks if symlinks exist, then checks if they are broken or not
    if [[ ! -L "$path" ]]; then 
      flag_boot_proceed=false
      return
    fi

    if [[ $1 = true && -z $(readlink -e "$path") ]]; then 
      try_fix_mounts
    else continue; 
    fi
    if [[ -z $(readlink -e "$path") ]]; then 
      flag_boot_proceed=false
      return
    fi
  done
  flag_boot_proceed=true
}

# main boot sequence
##########
## ROOT ##
##########
#https://stackoverflow.com/a/29969243
if [ $UID -eq 0 ]; then
  service ssh stop
  service ssh start

  is_mounts_valid true
  e_handel_boot_fail 3 false

  exec su "system" "$0" -- "$flag_boot_proceed"
fi 
[[ -z $1 ]] && e_handel_boot_fail 2
############
## system ##
############
e_handel_boot_fail 1

# check mounts access again
is_mounts_valid
e_handel_boot_fail 3

#install the rio toolchain if we haven't
if [[ -z "$(ls -A /home/system/wpilib/$COMP_YEAR/roborio)" ]]; then 
  source /home/system/wpi_codespace/downloader.bash rioToolChain /home/system/wpilib/$COMP_YEAR/roborio/
fi

cd /home/system/
./vscode/bin/code serve-web --cli-data-dir ./vscode/bin/cli --server-data-dir ./vscode/server_data --user-data-dir ./vscode/user_data --extensions-dir ./vscode/extensions --host 0.0.0.0 --port 8000 --without-connection-token --accept-server-license-terms

