# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Deployer
  class InstanceManager

    class Tier3 < InstanceManager

      def discover_bosh_ip
        if exists?
          server = cloud.get_vm(state.vm_cid)
          if server.has_key?('IPAddresses')
            ip = server['IPAddresses'].find { |addr| addr['AddressType'] == 1 }
            if ip != Config.bosh_ip
              Config.bosh_ip = ip
              logger.info("discovered bosh ip=#{Config.bosh_ip}")
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
