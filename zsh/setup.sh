#!/usr/bin/env zsh
set -ex
SCRIPT_PATH="${0:a:h}"
CONFIG_FILES=( .zshenv .zprofile .zshrc .zlogin .zlogout )

for arg in $(getopt 'r' $*); do
    case "$arg" in
        "-r")
            echo "Will delete old configs after backup."
            RESET="yes"
            ;;
    esac
done

cd "$HOME"
for config in $CONFIG_FILES; do
    if [ -f $config ]; then
        BACKUP_DIR=".zsh_backup.$(date +%s)"
        mkdir $BACKUP_DIR
        cp $CONFIG_FILES $BACKUP_DIR || true
        if [[ "$RESET" == "yes" ]]; then
            rm $CONFIG_FILES || true
        fi
        break
    fi
done

echo "__WENYU_RC_ROOT=\"${SCRIPT_PATH}\"" >>$HOME/.zshenv
echo 'source ${__WENYU_RC_ROOT}/01_zshenv' >>$HOME/.zshenv
echo 'source ${__WENYU_RC_ROOT}/02_zprofile' >>$HOME/.zprofile
echo 'source ${__WENYU_RC_ROOT}/03_zshrc' >>$HOME/.zshrc
echo 'source ${__WENYU_RC_ROOT}/04_zlogin' >>$HOME/.zlogin
echo 'source ${__WENYU_RC_ROOT}/99_zlogout' >>$HOME/.zlogout
