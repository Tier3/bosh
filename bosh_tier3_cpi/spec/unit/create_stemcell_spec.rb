# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#create_stemcell' do
    it "returns the name of the stemcell" do
      cloud = make_cloud

      stemcell_properties = { 'name' => 'my-awesome-stemcell' }
      expect(cloud.create_stemcell('/var/vcap', stemcell_properties)).to eq 'my-awesome-stemcell'
    end
  end
end