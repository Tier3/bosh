require 'spec_helper'
require 'fakefs/spec_helpers'
require 'bosh/dev/bat/aws_runner'

module Bosh::Dev::Bat
  describe AwsRunner do
    include FakeFS::SpecHelpers

    let(:bosh_cli) { instance_double('Bosh::Dev::Bat::BoshCli', run_bosh: true) }
    let(:shell) { instance_double('Bosh::Dev::Bat::Shell', run: true) }

    let(:bat_helper) do
      instance_double('Bosh::Dev::BatHelper',
                      artifacts_dir: '/fake_artifacts_dir',
                      micro_bosh_deployment_dir: '/fake_artifacts_dir/fake_micro_bosh_deployment_dir',
                      micro_bosh_deployment_name: 'fake_micro_bosh_deployment_name',
                      micro_bosh_stemcell_path: 'fake_micro_bosh_stemcell_path',
                      bosh_stemcell_path: 'fake_bosh_stemcell_path')
    end

    before do
      FileUtils.mkdir('/mnt')
      FileUtils.mkdir(bat_helper.artifacts_dir)

      Bosh::Dev::BatHelper.stub(:new).with('aws').and_return(bat_helper)
      Bosh::Dev::Bat::BoshCli.stub(:new).and_return(bosh_cli)
      Bosh::Dev::Bat::Shell.stub(:new).and_return(shell)

      ENV.stub(:to_hash).and_return({
                                      'BOSH_JENKINS_DEPLOYMENTS_REPO' => 'fake_BOSH_JENKINS_DEPLOYMENTS_REPO',
                                      'BOSH_VPC_SUBDOMAIN' => 'fake_BOSH_VPC_SUBDOMAIN',
                                    })

      subject.stub(stemcell_manifest: { 'version' => '6' }) # FIXME: Should be a collaborator!
    end

    describe '#deploy_micro' do
      it 'generates a micro manifest' do
        bosh_cli.should_receive(:run_bosh).with("aws generate micro_bosh '/mnt/deployments/fake_BOSH_VPC_SUBDOMAIN/aws_vpc_receipt.yml' '/mnt/deployments/fake_BOSH_VPC_SUBDOMAIN/aws_route53_receipt.yml'")
        subject.deploy_micro
      end

      it 'targets the micro' do
        bosh_cli.should_receive(:run_bosh).with('micro deployment fake_micro_bosh_deployment_name')
        subject.deploy_micro
      end

      it 'deploys the micro' do
        bosh_cli.should_receive(:run_bosh).with('micro deploy fake_micro_bosh_stemcell_path')
        subject.deploy_micro
      end

      it 'logs in to the micro' do
        bosh_cli.should_receive(:run_bosh).with('login admin admin')
        subject.deploy_micro
      end

      it 'uploads the bosh stemcell to the micro' do
        bosh_cli.should_receive(:run_bosh).with('upload stemcell fake_bosh_stemcell_path', debug_on_fail: true)
        subject.deploy_micro
      end

      it 'generates a bat manifest' do
        bosh_cli.should_receive(:run_bosh).with("aws generate bat '/mnt/deployments/fake_BOSH_VPC_SUBDOMAIN/aws_vpc_receipt.yml' '/mnt/deployments/fake_BOSH_VPC_SUBDOMAIN/aws_route53_receipt.yml' '6'")
        subject.deploy_micro
      end
    end

    describe '#teardown_micro' do
      it 'deletes the bat deployment' do
        bosh_cli.should_receive(:run_bosh).with('delete deployment bat', ignore_failures: true)
        subject.teardown_micro
      end

      it 'deletes the micro' do
        bosh_cli.should_receive(:run_bosh).with('micro delete', ignore_failures: true)
        subject.teardown_micro
      end

      it 'deletes the artifacts_dir' do
        expect {
          subject.teardown_micro
        }.to change { File.exists?(bat_helper.artifacts_dir) }.to(false)
      end
    end
  end
end
