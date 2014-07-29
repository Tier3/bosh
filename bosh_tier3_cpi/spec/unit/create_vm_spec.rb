# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do
  describe '#create_vm' do
    it "requires a network spec hash" do
      cloud = make_cloud
      
      expect{cloud.create_vm(nil, nil, nil, "bad hash")}.to raise_error ArgumentError
    end

    it "requires a single network" do
      cloud = make_cloud
      
      expect{cloud.create_vm(nil, nil, nil, {first: "blah", second: "blah"})}.to raise_error ArgumentError
    end

    it "requires an environment hash" do
      cloud = make_cloud
      networks = {
        'name' => {
          'type' => 'static',
          'cloud_properties' => {
            'name' => 'vlan_172.21.140'
          }
        }
      }

      expect{cloud.create_vm(nil, nil, nil, networks, nil, nil)}.to raise_error ArgumentError
    end

    it "creates and configures a vm and returns the vm name" do
      created_vm_name = ''
      cloud = make_cloud do |mock_client|
        # Stub and verify the CreateServer API call
        mock_client.should_receive(:post).with('/server/createserver/json', anything()) do |url, data|
          expect(data[:Template]).to eq 'TEMPLATE'
          expect(data[:Alias]).to match(/[A-Z]{6}/)
          expect(data[:HardwareGroupID]).to eq 123
          expect(data[:CPU]).to eq 4
          expect(data[:MemoryGB]).to eq 8
          expect(data[:Network]).to eq 'vlan_172.21.140'
          expect(data[:AccountAlias]).to eq 'DEV'
          expect(data[:LocationAlias]).to eq 'QA1'

          created_vm_name = "#{data[:LocationAlias]}#{data[:AccountAlias]}#{data[:Alias]}01"
          "{ \"Success\": true, \"RequestID\": 123 }"
        end

        # Stub and verify .wait_for
        mock_client.should_receive(:wait_for).with(123, 'QA1') do |&block|
          block.call({ 'Success' => true, 'Servers' => [created_vm_name] })
        end
      end

      # Stub SSH stuff
      Net::SCP.should_receive(:start).with('172.21.140.10', 'root', {password: 'password'})

      resource_pool = {
        'group_id' => 123,
        'cpu' => 4,
        'ram' => 8192
      }
      networks = {
        'name' => {
          'type' => 'dynamic',
          'cloud_properties' => {
            'name' => 'vlan_172.21.140'
          }
        }
      }

      expect(cloud.create_vm(nil, 'template', resource_pool, networks, nil, {})).to eq created_vm_name
    end

    context 'when network is dynamic' do
      it 'requires a Tier3 network name' do
        cloud = make_cloud
        networks = {
          'name' => {
            'type' => 'dynamic',
            'cloud_properties' => {}
          }
        }

        expect{cloud.create_vm(nil, nil, nil, networks)}.to raise_error ArgumentError
      end

      it 'creates vm with the network name' do
        created_vm_name = ''
        cloud = make_cloud do |mock_client|
          # Stub and verify the CreateServer API call
          mock_client.should_receive(:post).with('/server/createserver/json', anything()) do |url, data|
            expect(data[:Network]).to eq 'vlan_172.21.140'
            expect(data[:IPAddress]).to be_nil

            created_vm_name = "#{data[:LocationAlias]}#{data[:AccountAlias]}#{data[:Alias]}01"
            "{ \"Success\": true, \"RequestID\": 123 }"
          end

          # Stub and verify .wait_for
          mock_client.should_receive(:wait_for).with(123, 'QA1') do |&block|
            block.call({ 'Success' => true, 'Servers' => [created_vm_name] })
          end
        end

        # Stub SSH stuff
        Net::SCP.should_receive(:start).with('172.21.140.10', 'root', {password: 'password'})

        resource_pool = {
          'group_id' => 123,
          'cpu' => 4,
          'ram' => 8192
        }
        networks = {
          'name' => {
            'type' => 'dynamic',
            'cloud_properties' => {
              'name' => 'vlan_172.21.140'
            }
          }
        }

        expect(cloud.create_vm(nil, 'template', resource_pool, networks, nil, {})).to eq created_vm_name
      end
    end

    context 'when network is manual' do
      it 'requires a Tier3 network name' do
        cloud = make_cloud
        networks = {
          'name' => {
            'type' => 'manual',
            'cloud_properties' => {}
          }
        }

        expect{cloud.create_vm(nil, nil, nil, networks)}.to raise_error ArgumentError
      end

      it 'creates vm with the network name and IP address' do
        created_vm_name = ''
        cloud = make_cloud do |mock_client|
          # Stub and verify the CreateServer API call
          mock_client.should_receive(:post).with('/server/createserver/json', anything()) do |url, data|
            expect(data[:Network]).to eq 'vlan_172.21.140'
            expect(data[:IPAddress]).to eq '172.21.140.10'

            created_vm_name = "#{data[:LocationAlias]}#{data[:AccountAlias]}#{data[:Alias]}01"
            "{ \"Success\": true, \"RequestID\": 123 }"
          end

          # Stub and verify .wait_for
          mock_client.should_receive(:wait_for).with(123, 'QA1') do |&block|
            block.call({ 'Success' => true, 'Servers' => [created_vm_name] })
          end
        end

        # Stub SSH stuff
        Net::SCP.should_receive(:start).with('172.21.140.10', 'root', {password: 'password'})

        resource_pool = {
          'group_id' => 123,
          'cpu' => 4,
          'ram' => 8192
        }
        networks = {
          'name' => {
            'type' => 'manual',
            'ip' => '172.21.140.10',
            'cloud_properties' => {
              'name' => 'vlan_172.21.140'
            }
          }
        }

        expect(cloud.create_vm(nil, 'template', resource_pool, networks, nil, {})).to eq created_vm_name
      end
    end

  end
end