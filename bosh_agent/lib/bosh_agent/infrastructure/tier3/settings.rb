# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent
  class Infrastructure::Tier3::Settings

    VIP_NETWORK_TYPE = "vip"
    DHCP_NETWORK_TYPE = "dynamic"
    MANUAL_NETWORK_TYPE = "manual"

    SUPPORTED_NETWORK_TYPES = [
        DHCP_NETWORK_TYPE,
        MANUAL_NETWORK_TYPE
    ]

    # loads settings from /var/vcap/bosh/settings.json
    # this file will be created by Tier 3 platform with the VM configuration
    def load_settings
      settings_file = Config.settings_file
      json = File.read(settings_file)
      # perhaps catch json parser errors too and raise as LoadSettingsSerror?
      Yajl::Parser.new.parse(json)
    rescue Errno::ENOENT
      raise LoadSettingsError, "could not load settings from: #{settings_file}"
    end

    ##
    # Gets the network settings for this agent.
    #
    # @param [String] network_name Network name
    # @param [Hash] network_properties Network properties
    # @return [Hash] Network settings
    def get_network_settings(network_name, network_properties)
      type = network_properties["type"] || "manual"
      unless type && SUPPORTED_NETWORK_TYPES.include?(type)
        raise Bosh::Agent::StateError, "Unsupported network type '%s', valid types are: %s" %
            [type, SUPPORTED_NETWORK_TYPES.join(", ")]
      end

      # Nothing to do for "vip" and "manual" networks
      return nil if [VIP_NETWORK_TYPE, MANUAL_NETWORK_TYPE].include? type

      Bosh::Agent::Util.get_network_info
    end
  end
end
