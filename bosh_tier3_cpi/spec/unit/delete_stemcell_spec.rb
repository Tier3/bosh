# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#delete_stemcell?' do
    it "is not implemented" do
      cloud = make_cloud
      
      expect{cloud.create_stemcell(nil, nil)}.to raise_error Bosh::Clouds::NotImplemented
    end
  end
end