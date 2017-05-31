class Kontena::Plugin::Azure::NodeCommand < Kontena::Command
  subcommand "create", "Create a new node to Azure", load_subcommand('kontena/plugin/azure/nodes/create_command')
  subcommand "restart", "Restart Azure node", load_subcommand('kontena/plugin/azure/nodes/restart_command')
  subcommand "terminate", "Terminate Azure node", load_subcommand('kontena/plugin/azure/nodes/terminate_command')
end
