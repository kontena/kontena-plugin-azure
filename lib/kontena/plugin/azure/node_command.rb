require_relative 'nodes/create_command'
require_relative 'nodes/restart_command'
require_relative 'nodes/terminate_command'

class Kontena::Plugin::Azure::NodeCommand < Kontena::Command

  subcommand "create", "Create a new node to Azure", Kontena::Plugin::Azure::Nodes::CreateCommand
  subcommand "restart", "Restart Azure node", Kontena::Plugin::Azure::Nodes::RestartCommand
  subcommand "terminate", "Terminate Azure node", Kontena::Plugin::Azure::Nodes::TerminateCommand

  def execute
  end
end
