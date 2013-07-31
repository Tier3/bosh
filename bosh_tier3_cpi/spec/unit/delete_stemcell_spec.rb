# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#delete_stemcell?' do
    it "is a noop" do
      cloud = make_cloud
      
      expect(cloud.delete_stemcell(nil)).not_to raise_error
    end
  end
end