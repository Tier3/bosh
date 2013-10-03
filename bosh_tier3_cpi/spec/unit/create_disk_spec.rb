# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#create_disk' do
    it "requires an integer size" do
      cloud = make_cloud

      expect{cloud.create_disk('abc')}.to raise_error ArgumentError
    end

    it "enforces minimum disk size" do
      cloud = make_cloud

      expect{cloud.create_disk(1023)}.to raise_error Bosh::Clouds::CloudError
    end

    it "enforces maximum disk size" do
      cloud = make_cloud

      expect{cloud.create_disk(1024 * 1000 + 1)}.to raise_error Bosh::Clouds::CloudError
    end

    it "creates disk and returns id" do
      expected_disk_id = 'Disk1'
      cloud = make_cloud do |mock_client|
        # Stub and verify the create disk API call
        mock_client.should_receive(:post).with('/virtualdisk/create/json', anything()) do |url,data|
          expect(data['SizeGB']).to eq 1
          expect(data['AccountAlias']).to eq 'ELE'
          expect(data['Location']).to eq 'QA1'

          {
              :VirtualDisk => {
                  :ID => expected_disk_id,
                  :AccountAlias => data['AccountAlias'],
                  :Location => data['Location'],
                  :SizeGB => data['SizeGB']
              },
              :Success => true,
              :Message => 'OK',
              :StatusCode => 0
          }.to_json
        end
      end

      expect(cloud.create_disk(1024)).to eq expected_disk_id
    end

    it "raises error when creating the disk fails" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the create disk API call
        mock_client.should_receive(:post).with('/virtualdisk/create/json', anything()) do |url,data|
          {
              :Success => false,
              :Message => 'Error',
              :StatusCode => 1
          }.to_json
        end
      end

      expect{cloud.create_disk(1024)}.to raise_error
    end
  end
end
