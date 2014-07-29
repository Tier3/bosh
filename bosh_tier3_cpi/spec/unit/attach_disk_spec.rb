# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#attach_disk' do
    it "attaches disk" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the attach disk API call
        mock_client.should_receive(:post).with('/virtualdisk/attach/json', anything()) do |url, data|
          expect(data[:VirtualDiskID]).to eq 'Disk1'
          expect(data[:ServerName]).to eq 'QA1DEVABC01'
          expect(data[:AccountAlias]).to eq 'DEV'
          expect(data[:Location]).to eq 'QA1'

          {
              :AttachedDisk => {
                  :Name => 'Disk1',
                  :ScsiBusID => '0',
                  :ScsiDeviceID => '1',
                  :SizeGB => 1
              },
              :Success => true,
              :Message => 'OK',
              :StatusCode => 0
          }.to_json
        end
      end

      cloud.attach_disk('QA1DEVABC01','QA1:Disk1')
    end

    it "raises error when attaching disk fails" do
      cloud = make_cloud do |mock_client|
        # Stub and verify the attach disk API call
        mock_client.should_receive(:post).with('/virtualdisk/attach/json', anything()) do |url,data|
          {
              :Success => false,
              :Message => 'Error',
              :StatusCode => 1
          }.to_json
        end
      end

      expect{cloud.attach_disk('QA1DEVABC01','QA1:Disk1')}.to raise_error
    end
  end
end
