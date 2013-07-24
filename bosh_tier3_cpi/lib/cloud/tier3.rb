# Copyright (c) 2013 Tier 3, Inc.

module Bosh
  module Tier3Cloud; end
end

require "rest-client"

require "cloud"
require "cloud/tier3/helpers"
require "cloud/tier3/cloud"
require "cloud/tier3/version"

module Bosh
  module Clouds
    Tier3 = Bosh::Tier3Cloud::Cloud
  end
end

