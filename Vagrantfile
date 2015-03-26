require 'json'
require 'yaml'

VAGRANTFILE_API_VERSION = "2"

farmhouseYamlPath = File.expand_path("~/.farmhouse/Farmhouse.yaml")
afterScriptPath = File.expand_path("~/.farmhouse/after.sh")
aliasesPath = File.expand_path("~/.farmhouse/aliases")

require_relative 'scripts/farmhouse.rb'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	if File.exists? aliasesPath then
		config.vm.provision "file", source: aliasesPath, destination: "~/.bash_aliases"
	end

	Farmhouse.configure(config, YAML::load(File.read(farmhouseYamlPath)))

	if File.exists? afterScriptPath then
		config.vm.provision "shell", path: afterScriptPath
	end
end
