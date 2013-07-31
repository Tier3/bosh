require 'bosh/dev/bat'
require 'bosh/dev/bat_helper'
require 'bosh/dev/bat/bosh_cli'
require 'bosh/dev/bat/shell'

module Bosh::Dev::Bat
  class AwsRunner
    include Rake::FileUtilsExt

    def initialize
      @bat_helper = Bosh::Dev::BatHelper.new('aws')
      @mnt = ENV.fetch('FAKE_MNT', '/mnt')
      @shell = Shell.new
      @bosh_cli = BoshCli.new
    end

    def deploy_micro
      get_deployments_aws

      FileUtils.rm_rf(bat_helper.artifacts_dir)
      FileUtils.mkdir_p(bat_helper.micro_bosh_deployment_dir)

      Dir.chdir(bat_helper.artifacts_dir) do
        Dir.chdir(bat_helper.micro_bosh_deployment_dir) do
          bosh_cli.run_bosh "aws generate micro_bosh '#{vpc_outfile_path}' '#{route53_outfile_path}'"
        end
        bosh_cli.run_bosh "micro deployment #{bat_helper.micro_bosh_deployment_name}"
        bosh_cli.run_bosh "micro deploy #{bat_helper.micro_bosh_stemcell_path}"
        bosh_cli.run_bosh 'login admin admin'

        bosh_cli.run_bosh "upload stemcell #{bat_helper.bosh_stemcell_path}", debug_on_fail: true

        st_version = stemcell_version(bat_helper.bosh_stemcell_path)
        bosh_cli.run_bosh "aws generate bat '#{vpc_outfile_path}' '#{route53_outfile_path}' '#{st_version}'"
      end
    end

    def run_bats
      director = "micro.#{ENV['BOSH_VPC_SUBDOMAIN']}.cf-app.com"

      ENV['BAT_DIRECTOR'] = director
      ENV['BAT_STEMCELL'] = bat_helper.bosh_stemcell_path
      ENV['BAT_DEPLOYMENT_SPEC'] = File.join(bat_helper.artifacts_dir, 'bat.yml')
      ENV['BAT_VCAP_PASSWORD'] = 'c1oudc0w'
      ENV['BAT_FAST'] = 'true'
      ENV['BAT_DNS_HOST'] = Resolv.getaddress(director)

      Rake::Task['bat'].invoke
    end

    def teardown_micro
      if Dir.exists?(bat_helper.artifacts_dir)
        Dir.chdir(bat_helper.artifacts_dir) do
          bosh_cli.run_bosh 'delete deployment bat', :ignore_failures => true
          bosh_cli.run_bosh 'micro delete', :ignore_failures => true
        end
        FileUtils.rm_rf(bat_helper.artifacts_dir)
      end
    end

    private

    attr_reader :bat_helper, :mnt, :shell, :bosh_cli

    def vpc_outfile_path
      File.join(mnt, 'deployments', ENV.to_hash.fetch('BOSH_VPC_SUBDOMAIN'), 'aws_vpc_receipt.yml')
    end

    def route53_outfile_path
      File.join(mnt, 'deployments', ENV.to_hash.fetch('BOSH_VPC_SUBDOMAIN'), 'aws_route53_receipt.yml')
    end

    def get_deployments_aws
      Dir.chdir(mnt) do
        if Dir.exists?('deployments')
          Dir.chdir('deployments') do
            shell.run('git pull')
          end
        else
          shell.run("git clone #{ENV.to_hash.fetch('BOSH_JENKINS_DEPLOYMENTS_REPO')} deployments")
        end
      end
    end

    def stemcell_version(stemcell_tgz)
      stemcell_manifest(stemcell_tgz)['version']
    end

    def stemcell_manifest(stemcell_tgz)
      Dir.mktmpdir do |dir|
        shell.run('tar', 'xzf', stemcell_tgz, '--directory', dir, 'stemcell.MF')
        Psych.load_file(File.join(dir, 'stemcell.MF'))
      end
    end
  end
end
