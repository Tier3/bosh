# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Tier3Cloud

  module Helpers

    ##
    # Raises CloudError exception
    #
    def cloud_error(message)
      if @logger
        @logger.error(message)
      end
      raise Bosh::Clouds::CloudError, message
    end
  end
end

