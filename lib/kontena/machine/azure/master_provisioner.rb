require 'fileutils'
require 'erb'
require 'open3'
require 'json'
require_relative 'common'

module Kontena
  module Machine
    module Azure
      class MasterProvisioner
        include Kontena::Machine::RandomName
        include Kontena::Machine::CertHelper
        include Kontena::Cli::ShellSpinner
        include Common

        attr_reader :client, :http_client

        # @param [String] subscription_id Azure subscription id
        # @param [String] certificate Path to Azure management certificate
        def initialize(subscription_id, certificate)

          abort('Invalid management certificate') unless File.exists?(File.expand_path(certificate))

          @client = ::Azure
          client.management_certificate = File.expand_path(certificate)
          client.subscription_id        = subscription_id
          client.vm_management.initialize_external_logger(Logger.new) # We don't want all the output
        end

        def run!(opts)
          abort('Invalid ssh key') unless File.exists?(File.expand_path(opts[:ssh_key]))
          ssl_cert = nil
          if opts[:ssl_cert]
            abort('Invalid ssl cert (file not found)') unless File.exists?(File.expand_path(opts[:ssl_cert]))
            ssl_cert = File.read(File.expand_path(opts[:ssl_cert]))
          else
            spinner "Generating a self-signed SSL certificate" do
              ssl_cert = generate_self_signed_cert
            end
          end

          coreos_image = nil
          spinner "Finding latest #{'CoreOS stable'.colorize(:cyan)} image" do
            coreos_image = find_coreos_image
          end
          abort('Cannot find CoreOS image') if coreos_image.nil?

          cloud_service_name = generate_cloud_service_name
          vm_name = cloud_service_name
          master_url = ''
          public_ip = nil
          if opts[:virtual_network].nil?
            location = opts[:location].downcase.gsub(' ', '-')
            default_network_name = "kontena-#{location}"
            spinner "Creating a virtual network #{default_network_name.colorize(:cyan)}" do
              create_virtual_network(default_network_name, opts[:location]) unless virtual_network_exist?(default_network_name)
            end
            opts[:virtual_network] = default_network_name
            opts[:subnet] = 'subnet-1'
          end

          spinner "Creating an Azure Virtual Machine #{vm_name.colorize(:cyan)} to #{opts[:location].colorize(:cyan)}" do

            userdata_vars = opts.merge(
                ssl_cert: ssl_cert,
                server_name: opts[:name] || cloud_service_name.sub('kontena-master-', '')
            )

            params = {
                vm_name: vm_name,
                vm_user: 'core',
                location: opts[:location],
                image: coreos_image,
                custom_data: Base64.encode64(user_data(userdata_vars)),
                ssh_key: opts[:ssh_key]
            }

            options = {
                cloud_service_name: cloud_service_name,
                deployment_name: vm_name,
                virtual_network_name: opts[:virtual_network],
                subnet_name: opts[:subnet],
                tcp_endpoints: '443',
                private_key_file: File.expand_path(opts[:ssh_key]),
                ssh_port: 22,
                vm_size: opts[:size],
            }

            virtual_machine =  client.vm_management.create_virtual_machine(params,options)
            public_ip = virtual_machine.ipaddress
            master_url = "https://#{virtual_machine.ipaddress}"
          end
          Excon.defaults[:ssl_verify_peer] = false
          @http_client = Excon.new("#{master_url}", :connect_timeout => 10)

          spinner "Waiting for #{vm_name.colorize(:cyan)} to start (#{master_url})" do
            sleep 0.5 until master_running?
          end

          master_version = nil
          spinner "Retrieving Kontena Master version" do
            master_version = JSON.parse(@http_client.get(path: '/').body["version"]) rescue nil
          end

          spinner "Kontena Master #{master_version} is now running at #{master_url}".colorize(:green)

          data = {
            name: opts[:name] || cloud_service_name.sub('kontena-master-', ''),
            public_ip: public_ip,
            provider: 'azure',
            version: master_version,
            code: opts[:initial_admin_code]
          }
          if respond_to?(:certificate_public_key) && !opts[:ssl_cert]
            data[:ssl_certificate] = certificate_public_key(ssl_cert)
          end

          data
        end

        def user_data(vars)
          cloudinit_template = File.join(__dir__ , '/cloudinit_master.yml')
          erb(File.read(cloudinit_template), vars)
        end

        def master_running?
          http_client.get(path: '/').status == 200
        rescue
          false
        end

        def generate_cloud_service_name
          "kontena-master-#{generate_name}-#{rand(1..99)}"
        end
      end
    end
  end
end
