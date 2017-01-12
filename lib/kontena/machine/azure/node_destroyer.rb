require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'

module Kontena
  module Machine
    module Azure
      class NodeDestroyer

        include Kontena::Cli::ShellSpinner

        attr_reader :client, :api_client

        # @param [Kontena::Client] api_client Kontena api client
        # @param [String] subscription_id Azure subscription id
        # @param [String] certificate Path to Azure management certificate
        def initialize(api_client, subscription_id, certificate)
          @api_client = api_client
          abort('Invalid management certificate') unless File.exists?(File.expand_path(certificate))

          @client = ::Azure
          client.management_certificate = certificate
          client.subscription_id        = subscription_id
          client.vm_management.initialize_external_logger(Logger.new) # We don't want all the output
        end

        def run!(grid, name)

          vm = client.vm_management.get_virtual_machine(name, cloud_service_name(name, grid['name']))
          if vm
            spinner "Terminating Azure Virtual Machine #{name.colorize(:cyan)} " do
              client.vm_management.delete_virtual_machine(name, cloud_service_name(name, grid['name']))
            end
            storage_account = client.storage_management.list_storage_accounts.find{|a| a.label == cloud_service_name(name, grid['name'])}
            if storage_account
              spinner "Removing Azure Storage Account #{storage_account.name.colorize(:cyan)} " do
                client.storage_management.delete_storage_account(storage_account.name)
              end
            end
          else
            abort "\nCannot find Virtual Machine #{name.colorize(:cyan)} in Azure"
          end

          node = api_client.get("grids/#{grid['id']}/nodes")['nodes'].find{|n| n['name'] == name}
          if node
            spinner "Removing node #{name.colorize(:cyan)} from grid #{grid['name'].colorize(:cyan)} " do
              api_client.delete("nodes/#{grid['id']}/#{name}")
            end
          end
        end

        def cloud_service_name(vm_name, grid)
          "kontena-#{grid}-#{vm_name}"
        end
      end
    end
  end
end
