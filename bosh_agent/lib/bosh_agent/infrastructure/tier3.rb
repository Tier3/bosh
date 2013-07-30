# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent
  class Infrastructure::Tier3
    require 'bosh_agent/infrastructure/tier3/settings'

    def load_settings
      Settings.new.load_settings
    end

    def get_network_settings(network_name, properties)
      # Nothing to do
    end

  end
end

