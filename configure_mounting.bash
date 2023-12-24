#! /bin/bash

source /home/system/wpi_codespace/.env
source /home/system/wpi_codespace/config.conf

# $1-source $2-destination folder
crate_symlinks() {
    mkdir -p "$2" && ln -s "$1" "$2" 
}

crate_symlinks "/mnt/shared_caches/roborio" "/home/system/wpilib/$COMP_YEAR/" 
# crate_symlinks "/mnt/shared_caches/gradle/caches" "/home/system/.gradle" 
# crate_symlinks "/mnt/shared_caches/gradle/permwrapper" "/home/system/.gradle" 
