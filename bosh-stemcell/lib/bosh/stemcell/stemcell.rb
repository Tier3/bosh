require 'rake/file_utils'
require 'yaml'
require 'bosh/stemcell/ami'

module Bosh::Stemcell
  class Stemcell
    DEFAULT_AWS_AMI_REGION = 'us-east-1'

    attr_reader :path

    def initialize(path = '')
      @path = path
      validate_stemcell
    end

    def create_light_stemcell
      Stemcell.new(create_light_aws_stemcell) if infrastructure == 'aws'
    end

    def manifest
      @manifest ||= Psych.load(`tar -Oxzf #{path} stemcell.MF`)
    end

    def name
      manifest.fetch('name')
    end

    def infrastructure
      cloud_properties.fetch('infrastructure')
    end

    def version
      cloud_properties.fetch('version')
    end

    def light?
      infrastructure == 'aws' && ami_id
    end

    def ami_id(region = DEFAULT_AWS_AMI_REGION)
      cloud_properties.fetch('ami', {}).fetch(region, nil)
    end

    def extract(tar_options = {}, &block)
      Dir.mktmpdir do |tmp_dir|
        tar_cmd = "tar xzf #{path} --directory #{tmp_dir}"
        tar_cmd << " --exclude=#{tar_options[:exclude]}" if tar_options.has_key?(:exclude)

        Rake::FileUtilsExt.sh(tar_cmd)

        block.call(tmp_dir, manifest)
      end
    end

    private

    def cloud_properties
      manifest.fetch('cloud_properties')
    end

    def create_light_aws_stemcell
      extract(exclude: 'image') do |extracted_stemcell_dir|
        Dir.chdir(extracted_stemcell_dir) do
          FileUtils.touch('image', verbose: true)

          File.open('stemcell.MF', 'w') do |out|
            Psych.dump(new_manifest, out)
          end

          Rake::FileUtilsExt.sh("sudo tar cvzf #{light_stemcell_path} *")
        end
      end
      light_stemcell_path
    end

    def new_manifest
      ami = Bosh::Stemcell::Ami.new(self)
      ami_id = ami.publish
      manifest['cloud_properties']['ami'] = { ami.region => ami_id }
      manifest
    end

    def light_stemcell_name
      "light-#{File.basename(path)}"
    end

    def light_stemcell_path
      File.join(File.dirname(path), light_stemcell_name)
    end

    def validate_stemcell
      raise "Cannot find file `#{path}'" unless File.exists?(path)
    end
  end
end
