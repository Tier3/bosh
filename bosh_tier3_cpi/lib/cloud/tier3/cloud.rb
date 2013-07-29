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
    def initialize(options)
      @options = options.dup.freeze
      validate_options
      @logger = Bosh::Clouds::Config.logger
    end

    ##
    # Reads current vm name.
    #
    def current_vm_id
      # TODO build vm id - hostname?
    end

    ##
    # Returns name of well-known stemcell template
    #
    # @param [String] image_path local filesystem path to a stemcell image
    # @param [Hash] cloud_properties Tier3-specific stemcell properties
    # @option cloud_properties [String] kernel_id
    #   AKI, auto-selected based on the region, unless specified
    # @option cloud_properties [String] root_device_name
    #   block device path (e.g. /dev/sda1), provided by the stemcell manifest, unless specified
    # @option cloud_properties [String] architecture
    #   instruction set architecture (e.g. x86_64), provided by the stemcell manifest,
    #   unless specified
    # @option cloud_properties [String] disk (2048)
    #   root disk size
    # @return [String] EC2 AMI name of the stemcell
    def create_stemcell(image_path, stemcell_properties)
      with_thread_name("create_stemcell(#{image_path}...)") do
        begin
        rescue => e
          logger.error(e)
          raise e
        ensure
        end
      end
    end

    # Delete a stemcell and the accompanying snapshots
    # @param [String] stemcell_id
    # NB: this is a no-op
    def delete_stemcell(stemcell_id)
      with_thread_name("delete_stemcell(#{stemcell_id})") do
        logger.info(%Q[delete_stemcell: no-op])
      end
    end

    ##
    # Create an VM and wait until it's in running state
    # @param [String] agent_id agent id associated with new VM
    # @param [String] stemcell_id AMI id of the stemcell used to
    #  create the new instance
    # @param [Hash] resource_pool resource pool specification
    # @param [Hash] network_spec network specification, if it contains
    #  security groups they must already exist
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
          # TODO
        rescue => e # is this rescuing too much?
          logger.error(%Q[Failed to create instance: #{e.message}\n#{e.backtrace.join("\n")}])
          raise e
        end
      end
    end

    ##
    # Delete VM and wait until it reports as deleted
    # @param [String] VM name
    def delete_vm(instance_id)
      with_thread_name("delete_vm(#{instance_id})") do
        logger.info("Deleting VM '#{instance_id}'")
        # TODO
      end
    end

    ##
    # Has VM
    # @param [String] Name of NM
    def has_vm?(instance_id)
      with_thread_name("has_vm?(#{instance_id})") do
        # TODO
      end
    end

    ##
    # Reboot VM
    # @param [String] Name of VM
    def reboot_vm(instance_id)
      with_thread_name("reboot_vm(#{instance_id})") do
        # TODO
      end
    end

    # @param [String] Name of VM
    # @param [Hash] metadata metadata key/value pairs
    # @return [void]
    def set_vm_metadata(vm, metadata)
      # TODO use VMware metadata like vsphere?
    end

    # Configure network. NB: this is a no-op for Tier 3 platform
    # @param [String] instance_id Name of VM
    # @param [Hash] network_spec network properties
    # @raise [Bosh::Clouds:NotSupported] if there's a network change that requires the recreation of the VM
    def configure_networks(instance_id, network_spec)
      with_thread_name("configure_networks(#{instance_id}, ...)") do
        logger.info("Configuring '#{instance_id}' to use new network settings: #{network_spec.pretty_inspect}")
        # TODO should be no-op
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

        logger.info("Creating volume '#{volume.id}'")
        # TODO return volume.id
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
        # TODO snapshot.id
      end
    end

    # Delete a disk snapshot
    # @param [String] snapshot_id snapshot id to delete
    def delete_snapshot(snapshot_id)
      with_thread_name("delete_snapshot(#{snapshot_id})") do
        logger.info("snapshot '#{snapshot_id}' deleted")
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

    ##
    # Checks if options passed to CPI are valid and can actually
    # be used to create all required data structures etc.
    #
    def validate_options
      required_keys = {
          "tier3" => ["access_key_id", "secret_access_key", "region", "default_key_name"],
          "registry" => ["endpoint", "user", "password"],
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
