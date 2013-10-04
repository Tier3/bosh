# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Deployer
  class InstanceManager

    class Tier3 < InstanceManager

      def update_spec(spec)
        properties = spec.properties
        properties["tier3"] =
          Config.spec_properties["tier3"] ||
          Config.cloud_options["properties"]["tier3"].dup
        spec.delete("networks")
      end

      def remote_tunnel(port)
        # NB: this is a no-op since we don't use the registry
      end

      def discover_bosh_ip
        if exists?
          server = cloud.get_vm(state.vm_cid)
          if server.nil?
            logger.debug("discover_bosh_ip: server #{state.vm_cid} not found!")
          else
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
        end

        super
      end

      def service_ip
        discover_bosh_ip
      end

      # @return [Integer] size in MiB
      def disk_size(cid)
        # Tier3 stores disk size in GiB but we work with MiB
        cloud.get_disk_size(cid).size * 1024
      end

      def persistent_disk_changed?
        # since Tier3 stores disk size in GiB and we use MiB there
        # is a risk of conversion errors which lead to an unnecessary
        # disk migration, so we need to do a double conversion
        # here to avoid that
        requested = (Config.resources['persistent_disk'] / 1024.0).ceil * 1024
        requested != disk_size(state.disk_cid)
      end

    end
  end
end
