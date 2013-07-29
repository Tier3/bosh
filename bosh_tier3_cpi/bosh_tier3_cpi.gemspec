# -*- encoding: utf-8 -*-
# Copyright (c) 2013 Tier 3, Inc.
version = File.read(File.expand_path('../../BOSH_VERSION', __FILE__)).strip

Gem::Specification.new do |s|
  s.name         = "bosh_tier3_cpi"
  s.version      = version
  s.platform     = Gem::Platform::RUBY
  s.summary      = "BOSH Tier 3 CPI"
  s.description  = "BOSH Tier 3 CPI\n#{`git rev-parse HEAD`[0, 6]}"
  s.author       = "Tier 3"
  s.homepage     = 'https://github.com/Tier3/bosh'
  s.license      = 'Apache 2.0'
  s.email        = "support@tier3.com"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.files        = `git ls-files -- bin/* lib/*`.split("\n") + %w(README.md)
  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables  = %w(bosh_tier3_console)

  s.add_dependency "bosh_common", "~>#{version}"
  s.add_dependency "bosh_cpi", "~>#{version}"
  s.add_dependency "rest-client"
end
