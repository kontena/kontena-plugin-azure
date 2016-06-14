require 'kontena_cli'
require_relative 'kontena/plugin/azure'
require_relative 'kontena/plugin/azure_command'

Kontena::MainCommand.register("azure", "Azure specific commands", Kontena::Plugin::AzureCommand)
