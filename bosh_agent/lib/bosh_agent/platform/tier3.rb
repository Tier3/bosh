# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Agent
  class Platform::Tier3 < Platform::Ubuntu
    def update_passwords(settings)
      # Tier 3 handles its own password updates.
    end
  end
end
