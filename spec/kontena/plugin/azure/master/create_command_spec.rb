require 'spec_helper'
require 'kontena/plugin/azure_command'

describe Kontena::Plugin::Azure::Master::CreateCommand do

  let(:subject) do
    described_class.new(File.basename($0))
  end

  let(:provisioner) do
    spy(:provisioner)
  end

  describe '#run' do
    it 'raises usage error if no options are defined' do
      expect {
        subject.run([])
      }.to raise_error(Clamp::UsageError)
    end

    it 'passes options to provisioner' do
      id = 'id'
      cert = '/path/to/cert'
      ssh_key = '~/.ssh/id_rsa.pub'
      options = [
        '--subscription-id', id,
        '--subscription-cert', cert,
        '--location', 'West Europe',
        '--size', 'Small',
        '--ssh-key', ssh_key,
        '--no-prompt',
        '--skip-auth-provider'
      ]
      expect(subject).to receive(:provisioner).with(id, cert).and_return(provisioner)
      expect(provisioner).to receive(:run!).with(
        hash_including(ssh_key: ssh_key)
      )
      subject.run(options)
    end
  end
end
