#!/usr/bin/env bash

#
# is the the extra software is installed?
#
if [ ! -f /usr/local/extra_farmhouse_software_installed ]; then

    echo 'installing some extra software...'
    #
    # install zsh
    #
    apt-get install zsh -y
    
    #
    # install oh my zhs
    # (after.sh is run as the root user, but ssh is the vagrant user)
    #
    git clone git://github.com/robbyrussell/oh-my-zsh.git /home/vagrant/.oh-my-zsh
    cp /home/vagrant/.oh-my-zsh/templates/zshrc.zsh-template /home/vagrant/.zshrc
    chsh -s /usr/bin/zsh vagrant
    
    #
    # remember that the extra software is installed
    #    
    touch /usr/local/extra_farmhouse_software_installed
else    
    echo "extra software already installed... moving on..."
fi

#
# sync homebin to the vagrant user's bin
#
if [[ ! -d /home/vagrant/bin ]]; then
	mkdir /home/vagrant/bin
fi
rsync -rvzh --delete /srv/config/homebin/ /home/vagrant/bin/
echo " * rsync'd /srv/config/homebin                          to /home/vagrant/bin"