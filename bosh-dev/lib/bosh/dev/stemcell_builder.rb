require 'bosh/dev/build'

module Bosh::Dev
  class StemcellBuilder
    def initialize(environment, build = Bosh::Dev::Build.candidate)
      @build = build
      @environment = environment
      ENV['BUILD_PATH'] = environment.build_path
      ENV['WORK_PATH'] = environment.work_path
      ENV['STEMCELL_VERSION'] = environment.stemcell_version
    end

    def micro
      bosh_release_path = build.download_release
      Rake::Task['stemcell:micro'].invoke(bosh_release_path, environment.infrastructure, build.number)
    end

    def basic
      Rake::Task['stemcell:basic'].invoke(environment.infrastructure, build.number)
    end

    private

    attr_reader :build, :environment
  end
end
