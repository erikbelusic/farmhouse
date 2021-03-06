class Farmhouse
  def Farmhouse.configure(config, settings)
    # Set The VM Provider
    ENV['VAGRANT_DEFAULT_PROVIDER'] = settings["provider"] ||= "virtualbox"

    # Configure The Box
    config.vm.box = "laravel/homestead"
    config.vm.hostname = "farmhouse"

    # Configure A Private Network IP
    config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.11"

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.name = 'farmhouse'
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
    end

    # Configure A Few VMware Settings
    ["vmware_fusion", "vmware_workstation"].each do |vmware|
      config.vm.provider vmware do |v|
        v.vmx["displayName"] = "farmhouse"
        v.vmx["memsize"] = settings["memory"] ||= 2048
        v.vmx["numvcpus"] = settings["cpus"] ||= 1
        v.vmx["guestOS"] = "ubuntu-64"
      end
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8000
    config.vm.network "forwarded_port", guest: 443, host: 44300
    config.vm.network "forwarded_port", guest: 3306, host: 33060
    config.vm.network "forwarded_port", guest: 5432, host: 54320

    # Add Custom Ports From Configuration
    if settings.has_key?("ports")
      settings["ports"].each do |port|
        config.vm.network "forwarded_port", guest: port["guest"] || port["to"], host: port["host"] || port["send"], protocol: port["protocol"] ||= "tcp"
      end
    end

    # Configure The Public Key For SSH Access
    if settings.include? 'authorize'
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(File.expand_path(settings["authorize"]))]
      end
    end

    # Copy The SSH Private Keys To The Box
    if settings.include? 'keys'
      settings["keys"].each do |key|
        config.vm.provision "shell" do |s|
          s.privileged = false
          s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
          s.args = [File.read(File.expand_path(key)), key.split('/').last]
        end
      end
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil
    end

    # Install All The Configured Nginx Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
          if (site.has_key?("hhvm") && site["hhvm"])
            s.inline = "bash /vagrant/scripts/serve-hhvm.sh $1 \"$2\" $3"
            s.args = [site["map"], site["to"], site["port"] ||= "80"]
          else
            s.inline = "bash /vagrant/scripts/serve.sh $1 \"$2\" $3"
            s.args = [site["map"], site["to"], site["port"] ||= "80"]
          end
      end
    end

    # Configure All Of The Configured Databases
    settings["databases"].each do |db|
      config.vm.provision "shell" do |s|
        s.path = "./scripts/create-mysql.sh"
        s.args = [db]
      end

      config.vm.provision "shell" do |s|
        s.path = "./scripts/create-postgres.sh"
        s.args = [db]
      end
    end

    # Configure All Of The Server Environment Variables
    if settings.has_key?("variables")
      settings["variables"].each do |var|
        config.vm.provision "shell" do |s|
          s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php5/fpm/php-fpm.conf"
          s.args = [var["key"], var["value"]]
        end

        config.vm.provision "shell" do |s|
            s.inline = "echo \"\n#Set Farmhouse environment variable\nexport $1=$2\" >> /home/vagrant/.profile"
            s.args = [var["key"], var["value"]]
        end
      end

      config.vm.provision "shell" do |s|
        s.inline = "service php5-fpm restart"
      end
    end

    # Update Composer On Every Provision
    config.vm.provision "shell" do |s|
      s.inline = "/usr/local/bin/composer self-update"
    end

    # Configure Blackfire.io
    if settings.has_key?("blackfire")
      config.vm.provision "shell" do |s|
        s.path = "./scripts/blackfire.sh"
        s.args = [settings["blackfire"][0]["id"], settings["blackfire"][0]["token"]]
      end
    end

    # Local Machine Hosts
    #
    # If the Vagrant plugin hostsupdater (https://github.com/cogitatio/vagrant-hostsupdater) is
    # installed, the following will automatically configure your local machine's hosts file to
    # be aware of the domains specified below. Watch the provisioning script as you may need to
    # enter a password for Vagrant to access your hosts file.
    #
    # By default, we'll include the domains set up by VVV through the vvv-hosts file
    # located in the www/ directory.
    #
    # Other domains can be automatically added by including a vvv-hosts file containing
    # individual domains separated by whitespace in subdirectories of www/.
    if defined?(VagrantPlugins::HostsUpdater)
      # Define hosts array
      hosts = Array.new

      # Get site domains from configuration
      settings["sites"].each do |site|
        hosts.push(site["map"])
      end

      # Pass the found host names to the hostsupdater plugin so it can perform magic.
      config.hostsupdater.aliases = hosts
      config.hostsupdater.remove_on_suspend = true
    end

    # /srv/database/
    #
    # If a database directory exists in the same directory as your Vagrantfile,
    # a mapped directory inside the VM will be created that contains these files.
    # This directory is used to maintain default database scripts as well as backed
    # up mysql dumps (SQL files) that are to be imported automatically on vagrant up
    config.vm.synced_folder "database/", "/srv/database"

    # /srv/config/
    #
    # If a server-conf directory exists in the same directory as your Vagrantfile,
    # a mapped directory inside the VM will be created that contains these files.
    # This directory is currently used to maintain default config files for provisioning.
    config.vm.synced_folder "config/", "/srv/config"

    # Vagrant Triggers
    #
    # If the vagrant-triggers plugin is installed, we can run various scripts on Vagrant
    # state changes like `vagrant up`, `vagrant halt`, `vagrant suspend`, and `vagrant destroy`
    #
    # These scripts are run on the host machine, so we use `vagrant ssh` to tunnel back
    # into the VM and execute things. By default, each of these scripts calls db_backup
    # to create backups of all current databases. This can be overridden with custom
    # scripting. See the individual files in config/homebin/ for details.
    if defined? VagrantPlugins::Triggers
      config.trigger.before :halt, :stdout => true do
        run "vagrant ssh -c 'vagrant_halt'"
      end
      config.trigger.before :suspend, :stdout => true do
        run "vagrant ssh -c 'vagrant_suspend'"
      end
      config.trigger.before :destroy, :stdout => true do
        run "vagrant ssh -c 'vagrant_destroy'"
      end
    end
  
  end
end
