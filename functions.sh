#!/bin/bash
function run_as_root(){
  if [ -z $password ]; then
    echo 'please enter you password'
    read password
  fi

  run "echo ${password} | sudo -S $1"
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

function install(){
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
  run_as_root 'cp ./resources/10-evdev.conf /etc/X11/xorg.conf.d'
}


function install_rvm() {
  echo "Installing RVM"
  install 'curl'
  install 'libreadline-dev'

  bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

  echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function' >> ~/.bash_profile
  source ~/.bash_profile

  rvm pkg install readline
  rvm pkg install zlib
  rvm pkg install zlib

  echo installing ruby 1.9.2
  rvm install 1.9.2 --with-openssl-dir=~/.rvm/usr --with-zlib-dir=~/.rvm/usr
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

  echo "export JAVA_HOME=~/Applications/java/${java_version}" >> ~/.bashrc
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc

}

function install_intellij(){
  install_java

  echo "Installing IntelliJ"
  intellij_tmp_dir=~/tmp/intellij
  downloaded_file=$intellij_tmp_dir/idea.tar.gz
  target_dir=~/Applications

  mkdir -p $intellij_tmp_dir $target_dir

  wget -O $downloaded_file http://download.jetbrains.com/idea/ideaIU-10.5.2.tar.gz
  tar -xzf $downloaded_file -C $intellij_tmp_dir
  rm $downloaded_file

  intellij=`ls $intellij_tmp_dir`

  mv $intellij_tmp_dir/$intellij $target_dir/$intellij
  ln -s $target_dir/$intellij $target_dir/intellij
}

function disable_login_screen(){
  echo "Disabling enforced login"
  run_as_root 'cp ./resources/lightdm.conf /etc/lightdm'
}

function disable_screen_locking(){
  echo "Disabling screen locking"
  gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
}

function reboot(){
  echo "Rebooting"
  run_as_root "shutdown -r now"
}

