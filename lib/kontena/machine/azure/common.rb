module Kontena
  module Machine
    module Azure
      module Common

        def create_virtual_network(name, location)
          address_space = ['10.0.0.0/20']
          options = {subnet: [{:name => 'subnet-1',  :ip_address=>'10.0.0.0',  :cidr=>23}]}
          client.network_management.set_network_configuration(name, location, address_space, options)
        end

        def virtual_network_exist?(name)
          client.network_management.list_virtual_networks.find{|n| n.name == name}
        end

        def erb(template, vars)
          ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
        end

        # @return [String]
        def find_coreos_image
          images = client.vm_image_management.list_os_images.select { |i|
            i.name.include?('__CoreOS-Stable-')
          }.sort_by { |i|
            i.name.split('__CoreOS-Stable-')[1].to_i
          }
          image = images[-1]
          image.name
        end
      end
    end
  end
end
