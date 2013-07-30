# Copyright (c) 2013 Tier 3, Inc.

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

    ##
    # Returns name of well-known stemcell template
    # Since the stemcell template will be uploaded and available in advance,
    # this just checks to see if the 
    #
    # @param [String] image_path - Tier 3 ignored
    # @param [Hash] stemcell_properties - Tier 3 ignored
    # @return [String] name of the stemcell (VM template name)
    def create_stemcell(image_path, stemcell_properties)
      with_thread_name("create_stemcell(#{image_path}...)") do
        begin
          logger.debug("create_stemcell(#{image_path}, #{stemcell_properties.inspect}")
          template_name = api_properties['template']
          if has_vm?(template_name)
            template_name
          else
            nil # TODO correct return for not found?
          end
        rescue => e
          logger.error(e)
          raise
        end
      end
    end

    # Delete a stemcell and the accompanying snapshots
    # @param [String] stemcell_id
    # NB: this is a no-op in Tier 3 CPI
    def delete_stemcell(stemcell_id)
      with_thread_name("delete_stemcell(#{stemcell_id})") do
        logger.info(%Q[delete_stemcell: no-op])
      end
    end

    ##
    # Create an VM and wait until it's in running state
    # @param [String] agent_id - agent id associated with new VM
    # @param [String] stemcell_id - Template name to create new instance
    # @param [Hash] resource_pool - resource pool specification (TODO unused?)
    # @param [Hash] network_spec - network specification (TODO unused?)
    # @param [optional, Array] disk_locality list of disks that
    #   might be attached to this instance in the future, can be
    #   used as a placement hint (i.e. instance will only be created
    #   if resource pool availability zone is the same as disk
    #   availability zone)
    # @param [optional, Hash] environment data to be merged into
    #   agent settings
    #
    # @return [String] Name of the new virtual machine
    #
    def create_vm(agent_id, stemcell_id, resource_pool, network_spec, disk_locality = nil, environment = nil)
      with_thread_name("create_vm(#{agent_id}, ...)") do

        begin

          hardware_group_id = api_properties['group-id']

          vm_alias = ('A'..'Z').to_a.shuffle[0,6].join
          logger.debug("create_vm(#{agent_id}, ...) Template: #{stemcell_id} Alias: #{vm_alias} Hardware group ID: #{hardware_group_id}")

          data = {
            Template: stemcell_id,
            Alias: vm_alias, # NB: 6 chars max
            HardwareGroupID: api_properties['group-id'],
            ServerType: 1, # TODO how to customize?
            ServiceLevel: 2, # TODO how to customize?
            CPU: 2, # TODO how to customize? cloud_properties['cpu']
            MemoryGB: 4, # TODO
            # ExtraDriveGB: TODO
          }

          if api_properties.has_key?('account-alias')
            data['AccountAlias'] = api_properties['account-alias']
          end
          if api_properties.has_key?('location-alias')
            data['LocationAlias'] = api_properties['location-alias']
          end
          if api_properties.has_key?('network')
            data['Network'] = api_properties['network']
          end

          created_vm_name = nil

          response = @client.post('/server/createserver/json', data)
          resp_data = JSON.parse(response)

          success = resp_data['Success']
          request_id = resp_data['RequestID']

          if success and request_id > 0
            @client.wait_for(request_id)
          else
            status_code = resp_data['StatusCode']
            message = resp_data['Message']
            @logger.error("Error creating VM: #{message} status code: #{status_code}")
          end

          created_vm_name

        rescue => e # is this rescuing too much?
          logger.error(%Q[Failed to create VM: #{e.message}\n#{e.backtrace.join("\n")}])
          raise
        end

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
        logger.debug("has_vm?(#{instance_id}")
        data = { Name: instance_id }
        # TODO exceptions? check HTTP code?
        response = @client.post('/server/getserver/json', data)
        resp_data = JSON.parse(response)
        if resp_data.has_key?('Server')
          server = resp_data['Server']
          if not server.nil? and server.has_key?('ID')
            server['ID'] > 0
          else
            false
          end
        else
          false
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

        raise ArgumentError, "disk size needs to be an integer" unless size.kind_of?(Integer)
        cloud_error("Tier3 CPI minimum disk size is 1 GiB") if size < 1024
        cloud_error("Tier3 CPI maximum disk size is 1 TiB") if size > 1024 * 1000
        # TODO return volume.id (disk id)
      end
    end

    ##
    # Delete independent disk
    # @param [String] disk_id
    # @raise [Bosh::Clouds::CloudError] if disk is not in available state
    def delete_disk(disk_id)
      with_thread_name("delete_disk(#{disk_id})") do

        logger.info("Deleting disk `#{disk_id}'")

        tries = 10
        sleep_cb = ResourceWait.sleep_callback("Waiting for disk `#{disk_id}' to be deleted", tries)
        ensure_cb = Proc.new do |retries|
          cloud_error("Timed out waiting to delete volume `#{disk_id}'") if retries == tries
        end
        # TODO error = Tier3::EC2::Errors::Client::VolumeInUse

        Bosh::Common.retryable(tries: tries, sleep: sleep_cb, on: error, ensure: ensure_cb) do
          # TODO delete here
          true # return true to only retry on Exceptions
        end

        logger.info("Volume `#{disk_id}' has been deleted")
      end
    end

    # Attach an independent disk to VM
    # @param [String] instance_id Name of VM
    # @param [String] disk_id disk id of the disk to attach
    def attach_disk(instance_id, disk_id)
      with_thread_name("attach_disk(#{instance_id}, #{disk_id})") do
        # TODO
        logger.info("Attached `#{disk_id}' to `#{instance_id}'")
      end
    end

    # Take snapshot of disk NB: no-op for Tier 3
    # @param [String] disk_id disk id of the disk to take the snapshot of
    # @return [String] snapshot id
    def snapshot_disk(disk_id, metadata)
      with_thread_name("snapshot_disk(#{disk_id})") do
        # TODO is no-op?
        logger.info("Snapshot of disk '#{disk_id}' requested. This is a NO-OP")
        disk_id
      end
    end

    # Delete a disk snapshot
    # @param [String] snapshot_id snapshot id to delete
    def delete_snapshot(snapshot_id)
      with_thread_name("delete_snapshot(#{snapshot_id})") do
        # TODO is no-op?
        logger.info("Delete napshot of disk '#{disk_id}' requested. This is a NO-OP")
      end
    end

    # Detach an independent disk from a VM
    # @param [String] instance_id Name of VM to detach the disk from
    # @param [String] disk_id id of the disk to detach
    def detach_disk(instance_id, disk_id)
      with_thread_name("detach_disk(#{instance_id}, #{disk_id})") do
        # TODO
        logger.info("Detached `#{disk_id}' from `#{instance_id}'")
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
      not_implemented(:get_disks)
    end

    # @note Not implemented in the Tier3 CPI
    def validate_deployment(old_manifest, new_manifest)
      # Not implemented in VSphere CPI as well
      not_implemented(:validate_deployment)
    end

    private

    def api_properties
      @api_properties ||= options.fetch('api')
    end

    ##
    # Checks if options passed to CPI are valid and can actually
    # be used to create all required data structures etc.
    #
    def validate_options

      required_keys = {
          'api' => ['url', 'key', 'password', 'template', 'group-id']
      }

      missing_keys = []

      required_keys.each_pair do |key, values|
        values.each do |value|
          if (!options.has_key?(key) || !options[key].has_key?(value))
            missing_keys << "#{key}:#{value}"
          end
        end
      end

      raise ArgumentError, "missing configuration parameters > #{missing_keys.join(', ')}" unless missing_keys.empty?
    end
  end
end
