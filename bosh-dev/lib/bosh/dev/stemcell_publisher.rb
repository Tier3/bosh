require 'bosh/dev/pipeline'
require 'bosh/stemcell/stemcell'
require 'bosh/stemcell/aws/light_stemcell'

module Bosh::Dev
  class StemcellPublisher
    def initialize(environment)
      @environment = environment
    end

    def publish
      stemcell = Bosh::Stemcell::Stemcell.new(stemcell_filename)

      publish_light_stemcell(stemcell) if environment.infrastructure == 'aws'

      Pipeline.new.publish_stemcell(stemcell)
    end

    private

    attr_reader :environment

    def publish_light_stemcell(stemcell)
      light_stemcell = Bosh::Stemcell::Aws::LightStemcell.new(stemcell)
      light_stemcell.write_archive
      light_stemcell_stemcell = Bosh::Stemcell::Stemcell.new(light_stemcell.path)

      Pipeline.new.publish_stemcell(light_stemcell_stemcell)
    end

    def stemcell_filename # FIXME: Should be returned by StemcellBuilder#micro or StemcellBuilder#basic
      @stemcell_filename ||= Dir.glob("#{environment.directory}/work/work/*.tgz").first # see: stemcell_builder/stages/stemcell/apply.sh:48
    end
  end
end
