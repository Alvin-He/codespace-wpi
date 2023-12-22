#! /bin/bash
set -ex
#$1-target, $2-download to path
source /home/system/wpi_codespace/.env
source /home/system/wpi_codespace/config.conf

target=$1
path=$2

# attempt to get a lock of the install path
get_lock() {
    if [[ $FLOCKED ]]; then 
        echo "Lock acquired, starting download..."
        return
    fi
    echo "Locking install path..."
    export FLOCKED=true
    flock -e $path -c "$0 $target $path"
    exit 0
}

#$1-download link
download_vscode() {
    cd $path
    wget "$1" -O vscode_cli.tar.gz
    tar -zxf vscode_cli.tar.gz
    rm vscode_cli.tar.gz
}

#$1-download link
download_rioToolChain() {
    wget "$1" -O rio_toolchain.tgz
    tar -zxf rio_toolchain.tgz
    mv ./roborio-academic/* $path -f 
    rm rio_toolchain.tgz
    rm roborio-academic -R
}

ARCH=$(arch)
mkdir -p $path
if [[ ! -z $(ls $path) ]]; then 
    echo "Another container/process already handled the download, skipping $target"
    exit 0
fi # exit if another process already handled the download
get_lock
case $target in 
    vscode)
        case $ARCH in 
        "x86_64")
            download_vscode $x86_64_vscode_cli_download_link
        ;;
        "aarch64")
            download_vscode $aarch64_vscode_cli_download_link
        ;;
        esac
    ;;
    rioToolChain)
        case $ARCH in 
        "x86_64")
            download_rioToolChain $x86_64_cpp_rio_toolchanin_download_link
        ;;
        "aarch64")
            download_rioToolChain $aarch64_cpp_rio_toolchain_download_link
        ;;
        esac
    ;;
esac