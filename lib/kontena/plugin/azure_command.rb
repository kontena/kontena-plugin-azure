class Kontena::Plugin::AzureCommand < Kontena::Command
  subcommand 'master', 'Azure master related commands', load_subcommand('kontena/plugin/azure/master_command')
  subcommand 'node', 'Azure node related commands', load_subcommand('kontena/plugin/azure/node_command')
end
