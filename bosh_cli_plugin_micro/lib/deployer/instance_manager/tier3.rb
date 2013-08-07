# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Deployer
  class InstanceManager

    class Tier3 < InstanceManager

      def remote_tunnel(port)
        # NB: this is a no-op since we don't use the registry
      end

      def discover_bosh_ip
        if exists?
          server = cloud.get_vm(state.vm_cid)
          if server.has_key?('IPAddresses')
            rip = server['IPAddresses'].detect { |addr| addr['AddressType'] == 'RIP' or addr['AddressType'] == 1 }
            if rip.has_key?('Address')
              ip = rip['Address']
              if ip != Config.bosh_ip
                Config.bosh_ip = ip
                logger.info("discovered bosh ip=#{Config.bosh_ip}")
              end
            end
          end
        end

        super
      end

      def service_ip
        discover_bosh_ip
      end

    end
  end
end
