require 'securerandom'

module Kontena::Plugin::Azure::Master
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    
    option "--subscription-id", "SUBSCRIPTION ID", "Azure subscription id", required: true
    option "--subscription-cert", "CERTIFICATE", "Path to Azure management certificate", attribute_name: :certificate, required: true
    option "--size", "SIZE", "SIZE", default: 'Small'
    option "--network", "NETWORK", "Virtual Network name"
    option "--subnet", "SUBNET", "Subnet name"
    option "--ssh-key", "SSH KEY", "SSH private key file", required: true
    option "--location", "LOCATION", "Location", default: 'West Europe'
    option "--ssl-cert", "SSL CERT", "SSL certificate file"
    option "--vault-secret", "VAULT_SECRET", "Secret key for Vault"
    option "--vault-iv", "VAULT_IV", "Initialization vector for Vault"
    option "--version", "VERSION", "Define installed Kontena version", default: 'latest'

    def execute
      require 'kontena/machine/azure'
      provisioner = provisioner(subscription_id, certificate)
      provisioner.run!(
          ssh_key: ssh_key,
          ssl_cert: ssl_cert,
          size: size,
          virtual_network: network,
          subnet: subnet,
          location: location,
          version: version,
          vault_secret: vault_secret || SecureRandom.hex(24),
          vault_iv: vault_iv || SecureRandom.hex(24),
          initial_admin_code: SecureRandom.hex(16)
      )
    end

    # @param [String] subscription_id
    # @param [String] certificate
    # @return [Kontena::Machine::Azure::MasterProvisioner]
    def provisioner(subscription_id, certificate)
      Kontena::Machine::Azure::MasterProvisioner.new
    end
  end
end
