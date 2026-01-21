#! /bin/bash
VER=v08_00_00_84
QU=e17:prof

echo "Setup uboonecode ${VER}"
source /grid/fermiapp/products/uboone/setup_uboone_mcc9.sh

setup uboonecode $VER -q$QU