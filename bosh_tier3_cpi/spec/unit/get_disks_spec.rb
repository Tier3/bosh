# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#get_disks' do
    it "gets disks" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the attach disk API call
        mock_client.should_receive(:post).with('/virtualdisk/list/json', anything()) do |url,data|
          expect(data[:ServerName]).to eq 'QA1DEVABC01'
          expect(data[:AccountAlias]).to eq 'DEV'
          expect(data[:Location]).to eq 'QA1'

          {
              :VirtualDisks => [
                  :ID => 'Disk1',
                  :AccountAlias => 'DEV',
                  :Location => 'QA1',
                  :SizeGB => 1
              ],
              :Success => true,
              :Message => 'OK',
              :StatusCode => 0
          }.to_json
        end
      end

      disks = cloud.get_disks('QA1DEVABC01')
      expect(disks).to eq ['QA1:Disk1']
    end

    it "raises error when getting disks fails" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the attach disk API call
        mock_client.should_receive(:post).with('/virtualdisk/list/json', anything()) do |url,data|
          {
              :Success => false,
              :Message => 'Error',
              :StatusCode => 1
          }.to_json
        end
      end

      expect{cloud.get_disks('QA1DEVABC01')}.to raise_error
    end
  end
end
