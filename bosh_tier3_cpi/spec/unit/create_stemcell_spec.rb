# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#create_stemcell' do
    it "returns template name if template exists" do
      cloud = make_cloud
      cloud.should_receive(:has_vm?)
      .with('template')
      .and_return true
      
      expect(cloud.create_stemcell(nil, nil)).to eq 'template'
    end

    it "raises exception if the template doesn't exist" do
      cloud = make_cloud
      cloud.should_receive(:has_vm?)
      .with('template')
      .and_return false
      
      expect { cloud.create_stemcell(nil, nil) }.to raise_exception
   end
  end
end