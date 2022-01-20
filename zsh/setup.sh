#!/bin/bash
set -ex
SCRIPT_PATH="$(dirname $(realpath $0))"
echo "source ${SCRIPT_PATH}/01_zshenv" >>$HOME/.zshenv
echo "source ${SCRIPT_PATH}/02_zprofile" >>$HOME/.zprofile
echo "source ${SCRIPT_PATH}/03_zshrc" >>$HOME/.zshrc
echo "source ${SCRIPT_PATH}/04_zlogin" >>$HOME/.zlogin
echo "source ${SCRIPT_PATH}/99_zlogout" >>$HOME/.zlogout


