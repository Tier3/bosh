# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#has_vm?' do
    it "returns true if Tier3 vm exists" do
      cloud = make_cloud do |mock_client|
        mock_client.should_receive(:post)
        .with('/server/getserver/json', { Name: 'QA1ELETEST01'})
        .and_return('{"Success": true }')
      end
      
      expect(cloud.has_vm?('QA1ELETEST01')).to be_true
    end

    it "returns false if Tier3 vm doesn't exist" do
     cloud = make_cloud do |mock_client|
        mock_client.should_receive(:post)
        .with('/server/getserver/json', { Name: 'QA1ELETEST01'})
        .and_return('{"Success": false }')
      end
      
      expect(cloud.has_vm?('QA1ELETEST01')).to be_false
   end
  end
end