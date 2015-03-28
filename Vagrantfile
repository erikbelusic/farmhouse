require 'json'
require 'yaml'

VAGRANTFILE_API_VERSION = "2"

farmhouseYamlPath = File.expand_path("~/.farmhouse/Farmhouse.yaml")
afterScriptPath = File.expand_path("~/.farmhouse/after.sh")
aliasesPath = File.expand_path("~/.farmhouse/aliases")
farmhouseProvisionPath = File.expand_path("./scripts/farmhouse-provision.sh")
farmhouseImportPath = File.expand_path("./scripts/import-sql.sh")

require_relative 'scripts/farmhouse.rb'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	if File.exists? aliasesPath then
		config.vm.provision "file", source: aliasesPath, destination: "~/.bash_aliases"
	end

	Farmhouse.configure(config, YAML::load(File.read(farmhouseYamlPath)))

	# Run custom provisioning before after.sh
	if File.exists? farmhouseProvisionPath then
		config.vm.provision "shell", path: farmhouseProvisionPath
	end

	# Run custom import before after.sh
	if File.exists? farmhouseImportPath then
		config.vm.provision "shell", path: farmhouseImportPath
	end

	if File.exists? afterScriptPath then
		config.vm.provision "shell", path: afterScriptPath
	end
end
