# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent
  class Infrastructure::Tier3::Settings

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

    def get_network_settings(network_name, properties)
      # Nothing to do
    end
  end
end
