#! /bin/bash
set -ex
#$1-target, $2-download to path
source /home/system/wpi_codespace/.env
source /home/system/wpi_codespace/config.conf

path=$2

#$1-download link
download_vscode() {
    mkdir -p $path
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


case $1 in 
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