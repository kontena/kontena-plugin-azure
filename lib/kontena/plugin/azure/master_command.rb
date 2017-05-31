class Kontena::Plugin::Azure::MasterCommand < Kontena::Command
  subcommand "create", "Create a new master to Azure", load_subcommand('kontena/plugin/azure/master/create_command')
end
