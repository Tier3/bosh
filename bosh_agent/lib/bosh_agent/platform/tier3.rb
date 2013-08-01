# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent

  class Platform::Tier3 < Platform::Ubuntu
    def setup_networking
      # Tier 3 handles its own networking configuration.
    end
  end

end
