# Copyright (c) 2013 Tier 3, Inc.

require 'rspec'
require 'cloud/tier3'

def mock_cloud_options
  {
    'api' =>
    {
      'url' => 'https://api.tier3.com',
      'key' => 'apikey',
      'password' => 'password',
      'template' => 'template',
      'group-id' => 'group-id'
    }
  }
end

def make_cloud(options = nil)
  mock_client = double("Tier3Client").as_null_object
  yield mock_client if block_given?

  Bosh::Tier3Cloud::Cloud.new(options || mock_cloud_options, mock_client)
end

RSpec.configure do |config|
  config.before(:each) { Bosh::Clouds::Config.stub(:logger).and_return(double.as_null_object)  }
end