# Copyright (c) 2009-2013 VMware, Inc.
# Copyright (c) 2012 Piston Cloud Computing, Inc.

require 'rspec'
require 'spec_helper'
require 'rest-client'

describe Bosh::Tier3Cloud::Cloud do

  it "has_vm? returns true if Tier3 vm exists" do
    cloud = make_cloud do |mock_client|
      mock_client.stub(:post) {'{"Server": {"ID": 1234} }'}
    end
    
    expect(cloud.has_vm?('QA1ELETEST01')).to be_true
  end

  it "has_vm? returns false if Tier3 vm doesn't exists"

  it "has_vm? returns false if Tier3 vm state is :terminated"

  it "has_vm? returns false if Tier3 vm state is :deleted"
end