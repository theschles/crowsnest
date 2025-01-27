#!/usr/bin/env bash
#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

## Exit on Error
set -Ee

## Debug
# set -x

# Global Vars
TITLE="crowsnest - A Webcam Daemon for Raspberry Pi OS"

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Uninstaller requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function goodbye_msg {
    echo -e "Please remove manually the 'crowsnest' folder in ${HOME}"
    echo -e "Remove [update manager crowsnest] section from moonraker.conf!"
    echo -e "After that is done, please reboot!\nGoodBye...\n"
}

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

function install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

function cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}
##

function err_exit {
    if [ "${1}" != "0" ]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
    exit 1
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR


### Uninstall crowsnest
function ask_uninstall {
    local remove
    if  [ -x "/usr/local/bin/crowsnest" ] && [ -d "${HOME}/crowsnest" ]; then
        while true; do
        read -erp "Do you REALLY want to remove existing 'crowsnest'? (y/N) " -i "N" remove
            case "${remove}" in
                y|Y|yes|Yes|YES)
                    uninstall_crowsnest
                    remove_raspicam_fix
                    remove_logrotate
                    goodbye_msg
                    break
                ;;
                n|N|no|No|NO)
                    echo -e "\nYou answered '${remove}'! Uninstall will be aborted..."
                    echo -e "GoodBye...\n"
                    exit 1
                ;;
                *)
                    echo -e "\nInvalid input, please try again."
                ;;
            esac
        done
    else
        echo -e "\n'crowsnest' seems not installed."
        echo -e "Exiting. GoodBye ..."
    fi
}

function uninstall_crowsnest {
    local servicefile bin_path
    servicefile="/etc/systemd/system/crowsnest.service"
    bin_path="/usr/local/bin/crowsnest"
    echo -en "\nStopping crowsnest.service ...\r"
    sudo systemctl stop crowsnest.service &> /dev/null
    echo -e "Stopping crowsnest.service ... \t[OK]\r"
    echo -en "\nDisable crowsnest.service ...\r"
    sudo systemctl disable crowsnest.service &> /dev/null
    echo -e "Disable crowsnest.service ... \t[OK]\r"
    echo -en "Uninstalling crowsnest.service...\r"
    if [ -f "${servicefile}" ]; then
        sudo rm -f "${servicefile}"
    fi
    if [ -x "${bin_path}" ]; then
        sudo rm -f "${bin_path}"
    fi
    echo -e "Uninstalling crowsnest.service...[OK]\r"
}

function remove_raspicam_fix {
    if [ -f /etc/modprobe.d/bcm2835-v4l2.conf ] &&
    [ -f /proc/device-tree/model ] &&
    grep -q "Raspberry" /proc/device-tree/model ; then
        echo -en "Removing Raspicam Fix ...\r"
        sudo sed -i '/bcm2835/d' /etc/modules
        sudo rm -f /etc/modprobe.d/bcm2835-v4l2.conf
        echo -e "Removing Raspicam Fix ... [OK]"
    else
        echo -e "This is not a Raspberry Pi!"
        echo -e "Removing Raspicam Fix ... [SKIPPED]"
    fi
}

function remove_logrotate {
    echo -en "Removing Logrotate Rule ...\r"
    sudo rm -f /etc/logrotate.d/crowsnest
    echo -e "Removing Logrotate Rule ... [OK]"
}

#### MAIN
install_cleanup_trap
welcome_msg
ask_uninstall

exit 0
