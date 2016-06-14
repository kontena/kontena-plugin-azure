require_relative 'azure/master_command'
require_relative 'azure/node_command'

class Kontena::Plugin::AzureCommand < Kontena::Command

  subcommand 'master', 'Azure master related commands', Kontena::Plugin::Azure::MasterCommand
  subcommand 'node', 'Azure node related commands', Kontena::Plugin::Azure::NodeCommand

  def execute
  end
end
