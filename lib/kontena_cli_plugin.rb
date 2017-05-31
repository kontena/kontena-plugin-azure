require 'kontena_cli'
require 'kontena/plugin/azure'
require 'kontena/cli/subcommand_loader'

Kontena::MainCommand.register("azure", "Azure specific commands", Kontena::Cli::SubcommandLoader.new('kontena/plugin/azure_command'))
