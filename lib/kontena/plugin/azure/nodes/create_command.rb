require_relative '../common'
module Kontena::Plugin::Azure::Nodes
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Azure::Common

    option "--subscription-id", "SUBSCRIPTION ID", "Azure subscription id", required: true
    option "--subscription-cert", "CERTIFICATE", "Path to Azure management certificate", attribute_name: :certificate, required: true
    option "--size", "SIZE", "SIZE", default: 'Small'
    option "--network", "NETWORK", "Virtual Network name"
    option "--subnet", "SUBNET", "Subnet name"
    option "--ssh-key", "SSH KEY", "SSH private key file", required: true
    option "--location", "LOCATION", "Location", required: true
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
  end
end
