require 'spec_helper'
require 'kontena/plugin/azure_command'

describe Kontena::Plugin::Azure::Nodes::CreateCommand do

  let(:subject) do
    described_class.new(File.basename($0))
  end

  let(:provisioner) do
    spy(:provisioner)
  end

  let(:client) do
    spy(:client)
  end

  describe '#run' do
    before(:each) do
      allow(subject).to receive(:require_current_grid).and_return('test-grid')
      allow(subject).to receive(:require_api_url).and_return('http://master.example.com')
      allow(subject).to receive(:api_url).and_return('http://master.example.com')
      allow(subject).to receive(:require_token).and_return('12345')
      allow(subject).to receive(:fetch_grid).and_return({})
      allow(subject).to receive(:client).and_return(client)
    end

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
        '--ssh-key', ssh_key
      ]
      expect(subject).to receive(:provisioner).with(client, id, cert).and_return(provisioner)
      expect(provisioner).to receive(:run!).with(
        hash_including(ssh_key: ssh_key)
      )
      subject.run(options)
    end
  end
end
