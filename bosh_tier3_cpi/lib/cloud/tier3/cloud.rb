# Copyright (c) 2013 Tier 3, Inc.

require 'net/ssh'
require 'net/scp'

module Bosh::Tier3Cloud

  class Cloud < Bosh::Cloud
    include Helpers

    attr_reader   :options
    attr_accessor :logger

    ##
    # Initialize BOSH Tier3 CPI. The contents of sub-hashes are defined in the {file:README.md}
    # @param [Hash] options CPI options
    # @option options [Hash] tier3 Tier 3 specific options
    # @option options [Hash] agent agent options
    # @option options [Hash] registry agent options
    def initialize(options, client = nil)
      @options = options.dup.freeze
      validate_options

      @client = client || create_client

      @logger = Bosh::Clouds::Config.logger
    end

    def create_client
      client_options =
      {
        :key => api_properties['key'],
        :password => api_properties['password'],
        :url => api_properties['url']
      }

      return Bosh::Tier3Cloud::Tier3Client.new(client_options)
    end

    ##
    # Reads current vm name.
    #
    def current_vm_id
      begin
        Socket.gethostname
      rescue => e
        logger.error(e)
        raise
      end
    end

    # Tier3 doesn't support uploading of VM images at this time
    def create_stemcell(image_path, stemcell_properties)
      with_thread_name("create_stemcell(#{image_path}...)") do
        logger.debug("create_stemcell(image_path: #{image_path}, stemcell_properties: #{stemcell_properties.inspect})")
        stemcell_properties["name"]
      end
    end

    # Because we're not uploading stemcells we shouldn't be deleting them either
    def delete_stemcell(stemcell_id)
      with_thread_name("delete_stemcell(#{stemcell_id})") do
        logger.debug("delete_stemcell(stemcell_id: #{stemcell_id})")
      end
    end

    ##
    # Create a VM and wait until it's in running state
    # @param [String] agent_id - agent id associated with new VM
    # @param [String] stemcell_id - Template name to create new instance
    # @param [Hash] resource_pool - resource pool specification (TODO unused?)
    # @param [Hash] networks - network specification (TODO unused?)
    # @param [optional, Array] disk_locality list of disks that
    #   might be attached to this instance in the future, can be
    #   used as a placement hint (i.e. instance will only be created
    #   if resource pool availability zone is the same as disk
    #   availability zone)
    # @param [optional, Hash] env - data to be merged into
    #   agent settings
    #
    # @return [String] Name of the new virtual machine
    #
    def create_vm(agent_id, stemcell_id, resource_pool,
                  networks, disk_locality = nil, env = nil)
      with_thread_name("create_vm(#{agent_id}, ...)") do

        unless networks.is_a?(Hash)
          raise ArgumentError, "Invalid network spec, Hash expected, #{networks.class} provided"
        end
        unless networks.length == 1
          raise ArgumentError, "Invalid network spec - only one network should be provided"
        end

        network = networks.values[0]
        unless network['type'] == 'dynamic'
          raise ArgumentError, "Invalid network spec - network type must be dynamic"
        end

        vlan_name = network['cloud_properties']['name']
        if vlan_name.nil? or vlan_name.empty?
          raise ArgumentError, "Invalid network spec, network -> cloud_properties -> name is nil or empty"
        end

        unless env.is_a?(Hash)
          raise ArgumentError, "Invalid env spec, Hash expected, #{env.class} provided"
        end

        hardware_group_id = resource_pool['group_id']

        unless hardware_group_id.is_a?(Integer)
          raise ArgumentError, "Invalid hardware group id, integer expected, #{hardware_group_id.class} provided"
        end

        vm_alias = ('A'..'Z').to_a.shuffle[0,6].join
        cpu = resource_pool['cpu'] || 1
        memory_mb = resource_pool['ram'] || 2048
        memory_gb = memory_mb / 1024

        logger.debug("create_vm(#{agent_id}, ...) Template: #{stemcell_id} Alias: #{vm_alias} Hardware group ID: #{hardware_group_id} Cpu: #{cpu} MemoryGB: #{memory_gb}")

        data = {
          # TODO: this is a temporary hack to work around the fact that the Platform is case-sensitive
          # on template name right now.  Should be fixed in Control.
          Template: stemcell_id.upcase,
          Alias: vm_alias, # NB: 6 chars max
          HardwareGroupID: hardware_group_id,
          ServerType: 1, # TODO customize?
          ServiceLevel: 2, # TODO customize?
          CPU: cpu,
          MemoryGB: memory_gb,
          Network: vlan_name,
          # ExtraDriveGB: TODO persistent disk
        }

        if api_properties.has_key?('account_alias')
          data[:AccountAlias] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data[:LocationAlias] = api_properties['location_alias']
        end

        created_vm_name = nil

        response = @client.post('/server/createserver/json', data)
        resp_data = JSON.parse(response)

        success = resp_data['Success']
        request_id = resp_data['RequestID']

        if success and request_id > 0
          @client.wait_for(request_id) do |resp_data|
            if resp_data['Success'] == true and resp_data.has_key?('Servers')
                created_vm_name = resp_data['Servers'][0]
            else
              raise "Could not get created VM name"
            end
          end
        else
          status_code = resp_data['StatusCode']
          message = resp_data['Message']
          msg = "Error creating VM: #{message} status code: #{status_code}"
          @logger.error(msg)
          raise msg
        end

        configure_agent(created_vm_name, agent_id, env)

        return created_vm_name
      end
    end

    ##
    # Delete VM and wait until it reports as deleted
    # @param [String] VM name
    def delete_vm(instance_id)
      with_thread_name("delete_vm(#{instance_id})") do
        logger.info("Deleting VM '#{instance_id}'")
        begin

          logger.debug("delete_vm(#{instance_id})")

          data = { Name: instance_id }

          response = @client.post('/server/deleteserver/json', data)
          resp_data = JSON.parse(response)

          success = resp_data['Success']
          request_id = resp_data['RequestID']

          if success and request_id > 0
            @client.wait_for(request_id)
          else
            status_code = resp_data['StatusCode']
            message = resp_data['Message']
            @logger.error("Error deleting VM: #{message} status code: #{status_code}")
          end

        rescue => e # is this rescuing too much?
          logger.error(%Q[Failed to delete VM: #{e.message}\n#{e.backtrace.join("\n")}])
          raise
        end
      end
    end

    ##
    # Has VM
    # @param [String] Name of NM
    def has_vm?(instance_id)
      with_thread_name("has_vm?(#{instance_id})") do
        begin
          logger.debug("has_vm?(#{instance_id})")
          data = { Name: instance_id }
          response = @client.post('/server/getserver/json', data)
          resp_data = JSON.parse(response)
          return resp_data['Success']
        rescue => e
          logger.error(e)
          raise
        end
      end
    end

    ##
    # Reboot VM
    # @param [String] Name of VM
    def reboot_vm(instance_id)
      with_thread_name("reboot_vm(#{instance_id})") do
        logger.info("Rebooting VM '#{instance_id}'")
        begin

          logger.debug("reboot_vm(#{instance_id})")

          data = { Name: instance_id }

          response = @client.post('/server/rebootserver/json', data)

          resp_data = JSON.parse(response)

          success = resp_data['Success']
          request_id = resp_data['RequestID']

          if success and request_id > 0
            @client.wait_for(request_id)
          else
            status_code = resp_data['StatusCode']
            message = resp_data['Message']
            @logger.error("Error rebooting VM: #{message} status code: #{status_code}")
          end

        rescue => e # is this rescuing too much?
          logger.error(%Q[Failed to reboot VM: #{e.message}\n#{e.backtrace.join("\n")}])
          raise
        end
      end
    end

    # @param [String] Name of VM
    # @param [Hash] metadata metadata key/value pairs
    # @return [void]
    def set_vm_metadata(vm, metadata)
      # TODO use VMware metadata like vsphere attributes?
    end

    # Configure network. NB: this is a no-op for Tier 3 platform
    # @param [String] instance_id Name of VM
    # @param [Hash] network_spec network properties
    # @raise [Bosh::Clouds:NotSupported] if there's a network change that requires the recreation of the VM
    def configure_networks(instance_id, network_spec)
      with_thread_name("configure_networks(#{instance_id}, ...)") do
        logger.info("Configuring '#{instance_id}' to use new network settings: #{network_spec.pretty_inspect}. This is a NO-OP")
        # TODO should be no-op? Unknown.
      end
    end

    ##
    # Creates a new independent disk
    # @param [Integer] size disk size in MiB
    # @param [optional, String] Name of VM that this disk will be attached to
    # @return [String] created disk id
    def create_disk(size, instance_id = nil)
      with_thread_name("create_disk(#{size}, #{instance_id})") do

        logger.info("Create disk: size `#{size}' instance: `#{instance_id}'")

        raise ArgumentError, "disk size needs to be an integer" unless size.kind_of?(Integer)
        cloud_error("Tier3 CPI minimum disk size is 1 GiB") if size < 1024
        cloud_error("Tier3 CPI maximum disk size is 1 TiB") if size > 1024 * 1000

        data = {
            'SizeGB' => size / 1024
        }

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/create/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']
        disk = resp_data['VirtualDisk']

        if success
          disk['ID']
        else
          msg = "Error creating disk: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end
      end
    end

    ##
    # Delete independent disk
    # @param [String] disk_id
    # @raise [Bosh::Clouds::CloudError] if disk is not in available state
    def delete_disk(disk_id)
      with_thread_name("delete_disk(#{disk_id})") do
        logger.info("Delete disk `#{disk_id}'")

        data = {
            'VirtualDiskID' => disk_id
        }

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/delete/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']

        if not success
          msg = "Error attaching disk: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end
      end
    end

    # Attach an independent disk to VM
    # @param [String] instance_id Name of VM
    # @param [String] disk_id disk id of the disk to attach
    def attach_disk(instance_id, disk_id)
      with_thread_name("attach_disk(#{instance_id}, #{disk_id})") do
        logger.info("Attach disk `#{disk_id}' to `#{instance_id}'")

        data = {
            'VirtualDiskID' => disk_id,
            'ServerName' => instance_id
        }

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/attach/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']

        if not success
          msg = "Error attaching disk: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end

        update_agent_settings(instance_id) do |settings|
          settings["disks"] ||= {}
          settings["disks"]["persistent"] ||= {}
          settings["disks"]["persistent"][disk_id] = resp_data['AttachedDisk']['ScsiDeviceID']
        end
      end
    end

    # Take snapshot of disk NB: no-op for Tier 3
    # @param [String] disk_id disk id of the disk to take the snapshot of
    # @return [String] snapshot id
    def snapshot_disk(disk_id, metadata)
      with_thread_name("snapshot_disk(#{disk_id})") do
        # Snapshots on virtual disks are not supported at this time
        logger.info("Not implemented: Snapshot of disk '#{disk_id}' requested. This is a NO-OP")
      end
    end

    # Delete a disk snapshot
    # @param [String] snapshot_id snapshot id to delete
    def delete_snapshot(snapshot_id)
      with_thread_name("delete_snapshot(#{snapshot_id})") do
        # Snapshots on virtual disks are not supported at this time
        logger.info("Not implemented: Delete snapshot '#{snapshot_id}' requested. This is a NO-OP")
      end
    end

    # Detach an independent disk from a VM
    # @param [String] instance_id Name of VM to detach the disk from
    # @param [String] disk_id id of the disk to detach
    def detach_disk(instance_id, disk_id)
      with_thread_name("detach_disk(#{instance_id}, #{disk_id})") do
        logger.info("Detach disk `#{disk_id}' from `#{instance_id}'")

        power_off_vm(instance_id)

        data = {
            'VirtualDiskID' => disk_id
        }

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/detach/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']

        if not success
          msg = "Error attaching disk: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end

        power_on_vm(instance_id)

        update_agent_settings(instance_id) do |settings|
          settings["disks"] ||= {}
          settings["disks"]["persistent"] ||= {}
          settings["disks"]["persistent"].delete(disk_id)
        end
      end
    end

    ##
    # List the attached disks of the VM.
    #
    # @param [String] vm_id is the CPI-standard vm_id (eg, returned from current_vm_id)
    #
    # @return [array[String]] list of opaque disk_ids that can be used with the
    # other disk-related methods on the CPI
    def get_disks(vm_id)
      with_thread_name("get_disks(#{vm_id})") do
        logger.info("Get disks for VM `#{vm_id}'")

        data = {
            'ServerName' => vm_id
        }

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/list/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']

        if not success
          msg = "Error getting disks: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end

        disks = resp_data['VirtualDisks']
        disks.map { |disk| disk['ID'] }.compact
      end
    end

    ##
    # Get the size of an attached disk.  Not part of the standard CPI interface but used by the Tier3 instance_manager.
    # TODO: This should probably be moved into a child Tier3 object like OpenStack and AWS do it
    #
    # @param [String] disk_id is the CPI-standard disk_id
    #
    # @return [Integer] size in GiB
    def get_disk_size(disk_id)
      with_thread_name("get_disk_size(#{disk_id})") do
        logger.info("Get size for disk `#{disk_id}'")

        data = {}

        if api_properties.has_key?('account_alias')
          data['AccountAlias'] = api_properties['account_alias']
        end
        if api_properties.has_key?('location_alias')
          data['Location'] = api_properties['location_alias']
        end

        response = @client.post('/virtualdisk/list/json', data)
        resp_data = JSON.parse(response)
        success = resp_data['Success']

        if not success
          msg = "Error getting disks: #{resp_data['Message']} status code: #{resp_data['StatusCode']}"
          @logger.error(msg)
          raise msg
        end

        disks = resp_data['VirtualDisks']
        return disks.find{|disk| disk['ID'] == disk_id}.SizeGB
      end
    end

    # @note Not implemented in the Tier3 CPI
    def validate_deployment(old_manifest, new_manifest)
      # Not implemented in VSphere CPI as well
      not_implemented(:validate_deployment)
    end

    ##
    # Get VM
    # @param [String] Name of NM
    def get_vm(instance_id)
      with_thread_name("get_vm(#{instance_id})") do
        begin
          logger.debug("get_vm(#{instance_id})")
          data = { Name: instance_id }
          response = @client.post('/server/getserver/json', data)
          resp_data = JSON.parse(response)
          return resp_data['Server']
        rescue => e
          logger.error(e)
          raise
        end
      end
    end

    private

    # We have to power off and on in order to detach persistent disks.
    # TODO: an argument can be made that the Tier3 API should do that for us automatically
    def power_on_vm(instance_id)
      with_thread_name("power_on_vm(#{instance_id})") do
        logger.debug("power_on_vm(#{instance_id})")

        data = { Name: instance_id }

        response = @client.post('/server/poweronserver/json', data)

        resp_data = JSON.parse(response)

        success = resp_data['Success']
        request_id = resp_data['RequestID']

        if success and request_id > 0
          @client.wait_for(request_id)
        else
          status_code = resp_data['StatusCode']
          message = resp_data['Message']
          @logger.error("Error powering on VM: #{message} status code: #{status_code}")
        end
      end
    end

    def power_off_vm(instance_id)
      with_thread_name("power_off_vm(#{instance_id})") do
        logger.debug("power_off_vm(#{instance_id})")

        data = { Name: instance_id }

        response = @client.post('/server/poweroffserver/json', data)

        resp_data = JSON.parse(response)

        success = resp_data['Success']
        request_id = resp_data['RequestID']

        if success and request_id > 0
          @client.wait_for(request_id)
        else
          status_code = resp_data['StatusCode']
          message = resp_data['Message']
          @logger.error("Error powering off VM: #{message} status code: #{status_code}")
        end
      end
    end

    def api_properties
      @api_properties ||= options['tier3']['api']
    end

    ##
    # Checks if options passed to CPI are valid and can actually
    # be used to create all required data structures etc.
    #
    def validate_options
      required_keys = {
          'api' => ['url', 'key', 'password', 'account_alias', 'location_alias']
      }

      missing_keys = []

      required_keys.each_pair do |key, values|
        values.each do |value|
          if (!options['tier3'].has_key?(key) || !options['tier3'][key].has_key?(value))
            missing_keys << "#{key}:#{value}"
          end
        end
      end

      raise ArgumentError, "missing configuration parameters > #{missing_keys.join(', ')}" unless missing_keys.empty?
    end

    def generate_disk_env
      {
        "system" => 0,
        "ephemeral" => 1,
        "persistent" => {}
      }
    end

    def generate_agent_env(name, agent_id, disk_env)
      vm_env = {
        "name" => name
      }

      env = {}
      env["vm"] = vm_env
      env["agent_id"] = agent_id
      env["disks"] = disk_env
      env.merge!(@options["agent"])
      env
    end

    def configure_agent(vm_name, agent_id, environment)
      disk_env = generate_disk_env
      env = generate_agent_env(vm_name, agent_id, disk_env)
      env["env"] = environment
      @logger.debug("Setting VM env: #{env.pretty_inspect}")

      ip_address = get_agent_ip_address(vm_name)
      password = get_agent_password(vm_name)

      set_agent_env(ip_address, password, env)
    end

    def set_agent_env(ip_address, password, env)
      begin
        Net::SCP.start(ip_address, 'root', { password: password }) do |scp|
          # write the initial settings.json file for the agent
          scp.upload!(StringIO.new(env.to_json), '/var/vcap/bosh/settings.json')

          # start the agent now that it has settings to read
          scp.session.exec!('rm /etc/sv/agent/down')
          scp.session.exec!('sv up agent')
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        retry
      end
    end

    def get_agent_ip_address(vm_name)
      data = {
        Name: vm_name
      }

      response = @client.post('/server/getserver/json', data)
      response_data = JSON.parse(response)

      return response_data['Server']['IPAddress']
    end

    def get_agent_password(vm_name)
      data = {
        Name: vm_name
      }

      response = @client.post('/server/getservercredentials/json', data)
      response_data = JSON.parse(response)

      return response_data['Password']
    end

    # TODO: This code could probably be merged somehow with configure_agent but
    # we're keeping it separate for now in the interest of time
    def update_agent_settings(vm_name)
      @logger.debug("Updating agent settings...")

      ip_address = get_agent_ip_address(vm_name)
      password = get_agent_password(vm_name)

      begin
        Net::SCP.start(ip_address, 'root', { password: password }) do |scp|
          settings = scp.download!('/var/vcap/bosh/settings.json')
          settings_data = JSON.parse(settings)
          yield settings_data
          scp.upload!(StringIO.new(settings_data.to_json), '/var/vcap/bosh/settings.json')

          @logger.debug("Updated agent settings: #{settings_data.pretty_inspect}")
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        retry
      end
    end

  end
end
