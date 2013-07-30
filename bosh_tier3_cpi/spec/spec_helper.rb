# Copyright (c) 2009-2013 VMware, Inc.
# Copyright (c) 2012 Piston Cloud Computing, Inc.
require 'rspec'

require 'cloud/tier3'

RSpec.configure do |config|
  config.before(:each) { Bosh::Clouds::Config.stub(:logger).and_return(double.as_null_object)  }
end