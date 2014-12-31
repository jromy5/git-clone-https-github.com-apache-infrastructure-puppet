require 'spec_helper'

describe 'orthrus' do
  shared_examples 'an orthrus installation' do
    it { should contain_package('orthrus').with_require(repo_resource) }
    it { should contain_exec('setuid-ortpasswd').with_require('Package[orthrus]') }
  end


  context 'on ubuntu' do
    let(:facts) do
      {
        :asfosname => 'ubuntu',
      }
    end
    let(:repo_resource) { 'Apt::Source[asf_internal]' }

    it_behaves_like 'an orthrus installation'
  end

  context 'on CentOS' do
    let(:facts) do
      {
        :asfosname => 'centos',
      }
    end
    let(:repo_resource) { 'Yumrepo[asf_internal]' }

    it_behaves_like 'an orthrus installation'
  end
end
