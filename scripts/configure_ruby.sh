#!/bin/bash

rvm install 1.9.3
rvm use --default 1.9.3
rvm autolibs 3

gem install bundler
gem install debugger-ruby_core_source
