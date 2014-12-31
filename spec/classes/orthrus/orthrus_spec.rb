require 'spec_helper'

describe 'orthrus' do
  context 'on ubuntu' do
    let(:facts) do
      {
        :asfosname => 'ubuntu',
      }
    end

    it { should contain_package('orthrus').with_require('Apt::Source[asf_internal]') }
  end

  context 'on CentOS' do
    let(:facts) do
      {
        :asfosname => 'centos',
      }
    end

    it { should contain_package('orthrus').with_require('Yumrepo[asf_internal]') }
  end
end
