#!/bin/bash

resources_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/resources"

function run_as_root(){
  run "echo password | sudo -S $1"
}

function run(){
  command=$1

  eval $command

  if [ $? != 0 ];
  then
    echo "Error running: ${command}"
    exit 1
  fi
}

function upgrade_system_packages(){
  echo "Upgrade OS packages"
  run_as_root "apt-get update"
  run_as_root "apt-get -y upgrade"
}

function install(){
  echo "Installing: $1"
  run_as_root "apt-get -y install $1"
}

function configure_system_time(){
  run_as_root 'echo "Europe/London" | sudo tee /etc/timezone'
  run_as_root 'sudo dpkg-reconfigure --frontend noninteractive tzdata'
}

function allow_user_to_sudo_without_password() {
  echo "Updating sudoers file to user to sudo without password"
  run_as_root "sed -i -e 's/admin ALL=(ALL) ALL/admin ALL=NOPASSWD: ALL/g' /etc/sudoers"
}

function install_vim(){
  echo "Installing vim"
  install 'vim'
}

function install_git(){
  echo "Installing Git"
  install 'git-core'
  install 'git-doc'
}

function fix_keyboard_mappings_for_mac(){
  echo "remapping problems keys for a Mac keyboard"
  echo "keycode 94 = grave asciitilde
keycode 12 = 3 sterling 3 sterling numbersign" > ~/.Xmodmap

  run_as_root 'mkdir -p /etc/X11/xorg.conf.d'
  run_as_root "cp ${resources_dir}/10-evdev.conf /etc/X11/xorg.conf.d"
}


function install_rvm() {
  echo "Installing RVM"
  install 'build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion'

  bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

  echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function' >> ~/.bash_profile
  source ~/.bash_profile

  local global_gem_file=$HOME/.rvm/gemsets/global.gems
  echo "rspec" >> $global_gem_file
  echo "rake" >> $global_gem_file 


  echo installing ruby 1.9.2
  run "rvm install 1.9.2"
}

function install_java(){
  echo "Installing Java 1.6"
  java_version=java-1.6
  target_dir=~/Applications/java
  tmp_dir=~/tmp/java
  downloaded_file=i$java_version.bin

  mkdir -p $target_dir $tmp_dir
  cd $target_dir
  wget -O $downloaded_file http://download.oracle.com/otn-pub/java/jdk/6u29-b11/jdk-6u29-linux-x64.bin 
  chmod +x $downloaded_file 
  echo | ./$downloaded_file

  extracted_jdk_dir=jdk1.6.0_29
  mv $extracted_jdk_dir $target_dir 
  cd -
   
  ln -s $target_dir/$extracted_jdk_dir $target_dir/$java_version

  JAVA_HOME=~/Applications/java/${java_version}
  echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc

}

function install_intellij(){
  install_java

  echo "Installing IntelliJ"
  intellij_tmp_dir=~/tmp/intellij
  downloaded_file=$intellij_tmp_dir/idea.tar.gz
  target_dir=~/Applications

  mkdir -p $intellij_tmp_dir $target_dir

  wget -O $downloaded_file http://download.jetbrains.com/idea/ideaIU-11.0.1.tar.gz
  tar -xzf $downloaded_file -C $intellij_tmp_dir
  rm $downloaded_file

  intellij=`ls $intellij_tmp_dir`
  sed -i "2i JAVA_HOME=$JAVA_HOME" $intellij_tmp_dir/$intellij/bin/idea.sh

  mv $intellij_tmp_dir/$intellij $target_dir/$intellij
  ln -s $target_dir/$intellij $target_dir/intellij

  # up default memory settings for Intellij
  run "sed -i -e 's/-Xms.*/-Xms1024m/g' ${target_dir}/intellij/bin/idea.vmoptions"
  run "sed -i -e 's/-Xmx.*/-Xms1024m/g' ${target_dir}/intellij/bin/idea.vmoptions"

  # Add shortcut for intellij
  local shortcuts_dir=~/.local/share/applications
  
  mkdir -p $shortcuts_dir
  cp $resources_dir/intellij.desktop $shortcuts_dir
}

function install_imagemagick(){
    install 'imagemagick'
    install 'libmagickwand-dev'
}

function disable_login_screen(){
  echo "Disabling enforced login"
  run "sed -i -e \"s/autologin-user=user/autologin-user=$USER/g\" ${resources_dir}/lightdm.conf"
  run_as_root "cp ${resources_dir}/lightdm.conf /etc/lightdm/lightdm.conf"
}

function disable_screen_locking(){
  echo "Disabling screen locking"
  gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
}

function install_memcached(){
  echo Installing Memcached
  install 'memcached'
}

function reboot(){
  echo "Rebooting"
  run_as_root "shutdown -r now"
}

