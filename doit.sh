#!/bin/bash

tmp=/tmp/devup

function download_devup() {
  mkdir -p /tmp/devup
  wget -O $tmp/devup.tar.gz 'https://github.com/lashd/devup/tarball/master'
  tar -xzf $tmp/devup.tar.gz -C $tmp
}
download_devup

. $tmp/lashd-dev*/functions.sh
allow_user_to_sudo_without_password
configure_system_time
install_vim
install_git
fix_keyboard_mappings_for_mac
install_rvm
install_intellij
disable_login_screen
disable_screen_locking
reboot
