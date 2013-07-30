# Copyright (c) 2009-2013 VMware, Inc.
# Copyright (c) 2012 Piston Cloud Computing, Inc.

require 'spec_helper'

describe Bosh::Tier3Cloud::Cloud do

  it "has_vm? returns true if Tier3 vm exists" do
    1.should == 2
  end

  it "has_vm? returns false if Tier3 vm doesn't exists" do
    1.should == 2
  end

  it "has_vm? returns false if Tier3 vm state is :terminated" do
    1.should == 2
  end

  it "has_vm? returns false if Tier3 vm state is :deleted" do
    1.should == 2
  end
end