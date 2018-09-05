#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other useful programs
# @author Rahul Soibam
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot "Hi! I'm going to install toolings and configure the system. Here I go..."

# Ask for the administrator password upfront
bot "I need you to enter your sudo password so I can install some things:"
sudo -v

# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

bot "Do you want me to setup this machine to allow you to run sudo without a password?\nPlease read here to see what I am doing:\nhttp://wiki.summercode.com/sudo_without_a_password_in_mac_os_x \n"

read -r -p "Make sudo passwordless? [y|N] " response

if [[ $response =~ (yes|y|Y) ]];then
    sudo cp /etc/sudoers /etc/sudoers.back
    echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers > /dev/null
    bot "You can now run sudo commands without password!"
fi

# /etc/hosts
read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file) [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    action "cp /etc/hosts /etc/hosts.backup"
    sudo cp /etc/hosts /etc/hosts.backup
    ok
    action "cp ./configs/hosts /etc/hosts"
    sudo cp ./configs/hosts /etc/hosts
    ok
    bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
fi

read -r -p "What is your github.com username? " githubuser

read -r -p "What is your first name? " firstname
read -r -p "What is your last name? " lastname
fullname="$firstname $lastname"

bot "Great $fullname, "

read -r -p "What is your email? " email
if [[ ! $email ]];then
  error "you must provide an email to configure .gitconfig"
  exit 1
fi

running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

bot "Setting up homedir/.gitconfig"
sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig > /dev/null 2>&1 | true
sed -i "s/GITHUBEMAIL/$email/" ./homedir/.gitconfig;
sed -i "s/GITHUBUSER/$githubuser/" ./homedir/.gitconfig;

require_apt python3 python3-dev python3-pip

# Install thefuck
pip3 install thefuck
# skip those GUI clients, git command-line all the way
require_apt git
# need fontconfig to install/build fonts
require_apt fontconfig
# update zsh to latest
require_apt zsh
# update ruby to latest
require_apt ruby-full
# set zsh as the user login shell
CURRENTSHELL=$SHELL
if [[ "$CURRENTSHELL" != "/usr/bin/zsh" ]]; then
  bot "setting zsh (/usr/bin/zsh) as your shell (password required)"
  sudo bash -c 'echo "/usr/bin/zsh" >> /etc/shells'
  chsh -s /usr/bin/zsh
  ok
fi

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install oh-my-zsh plugins
if [[ ! -d "./oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel9k" ]]; then
  git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k
fi

if [[ ! -d "./oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

bot "creating symlinks for project dotfiles..."
pushd homedir > /dev/null 2>&1
now=$(date +"%Y.%m.%d.%H.%M.%S")

for file in .*; do
  if [[ $file == "." || $file == ".." ]]; then
    continue
  fi
  running "~/$file"
  # if the file exists:
  if [[ -e ~/$file ]]; then
      mkdir -p ~/.dotfiles_backup/$now
      mv ~/$file ~/.dotfiles_backup/$now/$file
      echo "backup saved as ~/.dotfiles_backup/$now/$file"
  fi
  # symlink might still exist
  unlink ~/$file > /dev/null 2>&1
  # create the link
  ln -s ~/dotfiles/homedir/$file ~/$file
  echo -en '\tlinked';ok
done

popd > /dev/null 2>&1


bot "Installing vim plugins"
# cmake is required to compile vim bundle YouCompleteMe
require_apt cmake
require_apt build-essential
# require_brew cmake
vim +'PlugInstall --sync' +qa > /dev/null 2>&1
python3 ~/.vim/plugged/YouCompleteMe/install.py --all

bot "installing fonts"
./fonts/install.sh
ok

bot "Woot! All done. Kill this terminal and launch iTerm"
