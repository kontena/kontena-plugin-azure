module Kontena::Plugin::Azure::Nodes
  class TerminateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions

    parameter "NAME", "Node name"
    option "--subscription-id", "SUBSCRIPTION ID", "Azure subscription id", required: true
    option "--subscription-cert", "CERTIFICATE", "Path to Azure management certificate", attribute_name: :certificate, required: true
    option "--force", :flag, "Force remove", default: false, attribute_name: :forced

    def execute
      require_api_url
      require_current_grid

      confirm_command(name) unless forced?

      require_relative '../../../machine/azure'

      grid = fetch_grid
      destroyer = destroyer(client(require_token), subscription_id, certificate)
      destroyer.run!(grid, name)
    end

    def fetch_grid
      client(require_token).get("grids/#{current_grid}")
    end

    # @param [Kontena::Client] client
    # @param [String] subscription_id
    # @param [String] certificate
    # @return [Kontena::Machine::Azure::NodeDestroyer]
    def destroyer(client, subscription_id, certificate)
      Kontena::Machine::Azure::NodeDestroyer.new(client, subscription_id, certificate)
    end
  end
end
