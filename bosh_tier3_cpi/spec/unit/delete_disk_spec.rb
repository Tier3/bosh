# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#delete_disk' do
    it "deletes disk" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the delete disk API call
        mock_client.should_receive(:post).with('/virtualdisk/delete/json', anything()) do |url,data|
          expect(data['VirtualDiskID']).to eq 'Disk1'
          expect(data['AccountAlias']).to eq 'ELE'
          expect(data['Location']).to eq 'QA1'

          {
              :Success => true,
              :Message => 'OK',
              :StatusCode => 0
          }.to_json
        end
      end

      cloud.delete_disk('Disk1')
    end

    it "raises error when deleting disk fails" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the delete disk API call
        mock_client.should_receive(:post).with('/virtualdisk/delete/json', anything()) do |url,data|
          {
              :Success => false,
              :Message => 'Error',
              :StatusCode => 1
          }.to_json
        end
      end

      expect{cloud.delete_disk('Disk1')}.to raise_error
    end
  end
end
