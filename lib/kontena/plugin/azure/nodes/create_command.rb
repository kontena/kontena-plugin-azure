require_relative '../common'
module Kontena::Plugin::Azure::Nodes
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Azure::Common

    option "--subscription-id", "ID", "Azure subscription id", required: true
    option "--subscription-cert", "CERT", "Path to Azure management certificate", attribute_name: :certificate, required: true
    option "--size", "SIZE", "Virtual machine size, see https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-sizes", required: true
    option "--ssh-key", "SSH KEY", "SSH private key file", required: true
    option "--location", "LOCATION", "Location", required: true
    option "--network", "NETWORK", "Virtual Network name"
    option "--subnet", "SUBNET", "Subnet name"
    option "--version", "VERSION", "Define installed Kontena version", default: 'latest'

    parameter "[NAME]", "Node name"

    def execute
      require_api_url
      require_current_grid

      require_relative '../../../machine/azure'
      grid = fetch_grid
      provisioner = provisioner(client(require_token), subscription_id, certificate)
      provisioner.run!(
        master_uri: api_url,
        grid_token: grid['token'],
        grid: current_grid,
        ssh_key: ssh_key,
        name: name,
        size: size,
        virtual_network: network,
        subnet: subnet,
        location: location,
        version: version
      )
    end

    # @param [Kontena::Client] client
    # @param [String] subscription_id
    # @param [String] certificate
    # @return [Kontena::Machine::Azure::NodeProvisioner]
    def provisioner(client, subscription_id, certificate)
      Kontena::Machine::Azure::NodeProvisioner.new client, subscription_id, certificate
    end

    # @return [Hash]
    def fetch_grid
      client(require_token).get("grids/#{current_grid}")
    end

    def default_location
      prompt.select("Choose location: ") do |menu|
        locations.each do |l|
          menu.choice l
        end
      end
    end

    def default_size
      size = prompt.select("Choose virtual machine size: ") do |menu|
        menu.default 3
        sizes.each do |s|
          menu.choice s
        end
        menu.choice 'Other'
      end
      if size == 'Other'
        size = prompt.ask("Virtual machine size? (see https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-sizes#size-tables)")
      end

      size
    end
  end
end
