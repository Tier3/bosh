# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent
  class Infrastructure::Tier3

    def load_settings
      {
        "blobstore" => {
          "provider" => Bosh::Agent::Config.blobstore_provider,
          "options" => Bosh::Agent::Config.blobstore_options,
        },
        "ntp" => [],
        "disks" => {
          "persistent" => {},
        },
        "mbus" => Bosh::Agent::Config.mbus,
      }
    end

    def get_network_settings(network_name, properties)
      # Nothing to do
    end
  end
end
