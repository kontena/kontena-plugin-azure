require 'fileutils'
require 'erb'
require 'open3'
require 'base64'
require_relative 'common'

module Kontena
  module Machine
    module Azure
      class NodeProvisioner
        include Kontena::Machine::RandomName
        include Kontena::Cli::ShellSpinner
        include Common

        attr_reader :client, :api_client

        # @param [Kontena::Client] api_client Kontena api client
        # @param [String] subscription_id Azure subscription id
        # @param [String] certificate Path to Azure management certificate
        def initialize(api_client, subscription_id, certificate)
          @api_client = api_client
          abort('Invalid management certificate') unless File.exists?(File.expand_path(certificate))

          @client = ::Azure
          client.management_certificate = File.expand_path(certificate)
          client.subscription_id        = subscription_id
          client.vm_management.initialize_external_logger(Logger.new) # We don't want all the output
        end

        def run!(opts)
          abort('Invalid ssh key') unless File.exists?(File.expand_path(opts[:ssh_key]))
          node = nil
          vm_name = opts[:name] || generate_name
          cloud_service_name = generate_cloud_service_name(vm_name, opts[:grid])

          coreos_image = nil
          spinner "Finding latest #{'CoreOS stable'.colorize(:cyan)} image" do
            coreos_image = find_coreos_image
          end
          abort('Cannot find CoreOS image') if coreos_image.nil?

          if opts[:virtual_network].nil?
            location = opts[:location].downcase.gsub(' ', '-')
            default_network_name = "kontena-#{location}"
            spinner "Creating virtual network #{default_network_name}" do
              create_virtual_network(default_network_name, opts[:location]) unless virtual_network_exist?(default_network_name)
            end
            opts[:virtual_network] = default_network_name
            opts[:subnet] = 'subnet-1'
          end

          spinner "Creating Azure Virtual Machine #{vm_name.colorize(:cyan)}" do
            userdata_vars = {
              version: opts[:version],
              master_uri: opts[:master_uri],
              grid_token: opts[:grid_token],
            }

            params = {
              vm_name: vm_name,
              vm_user: 'core',
              location: opts[:location],
              image: coreos_image,
              custom_data: Base64.encode64(user_data(userdata_vars)),
              ssh_key: File.expand_path(opts[:ssh_key])
            }
            options = {
              cloud_service_name: cloud_service_name,
              deployment_name: vm_name,
              virtual_network_name: opts[:virtual_network],
              subnet_name: opts[:subnet],
              tcp_endpoints: '80,443,6783',
              udp_endpoints: '1194,6783,6784',
              private_key_file: opts[:ssh_key],
              ssh_port: 22,
              vm_size: opts[:size],
            }

            client.vm_management.create_virtual_machine(params,options)
          end
          spinner "Waiting for node #{vm_name.colorize(:cyan)} join to grid #{opts[:grid].colorize(:cyan)} " do
            sleep 0.5 until node = vm_exists_in_grid?(opts[:grid], vm_name)
          end
          if node
            labels = [
              "region=#{cloud_service(cloud_service_name).location}",
              "az=#{cloud_service(cloud_service_name).location}",
              "provider=azure"
            ]
            set_labels(node, labels)
          end
        end

        def user_data(vars)
          cloudinit_template = File.join(__dir__ , '/cloudinit.yml')
          erb(File.read(cloudinit_template), vars)
        end

        def generate_name
          "#{super}-#{rand(1..99)}"
        end

        def generate_cloud_service_name(name, grid)
          "kontena-#{grid}-#{name}"
        end

        def vm_exists_in_grid?(grid, name)
          api_client.get("grids/#{grid}/nodes")['nodes'].find{|n| n['name'] == name}
        end

        def erb(template, vars)
          ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
        end

        def cloud_service_exist?(name)
          cloud_service(name)
        end

        def cloud_service(name)
          client.cloud_service_management.get_cloud_service(name)
        end

        def set_labels(node, labels)
          data = {}
          data[:labels] = labels
          api_client.put("nodes/#{node['grid']['id']}/#{node['id']}", data)
        end
      end

    end
  end
end
