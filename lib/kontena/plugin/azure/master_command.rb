require_relative 'master/create_command'

class Kontena::Plugin::Azure::MasterCommand < Kontena::Command

  subcommand "create", "Create a new master to Azure", Kontena::Plugin::Azure::Master::CreateCommand

  def execute
  end
end
