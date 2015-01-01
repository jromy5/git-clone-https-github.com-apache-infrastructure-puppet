# Required plugins:
#    vagrant-aws
#    vagrant-serverspec
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'aws'

Vagrant.configure("2") do |config|
  access_key_id = ENV['AWS_ACCESS_KEY_ID'] || File.read('.vagrant_key_id').chomp
  secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || File.read('.vagrant_secret_access_key').chomp
  keypair = ENV['AWS_KEYPAIR_NAME'] || File.read('.vagrant_keypair_name').chomp

  config.vm.box = 'dummy'
  config.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

  config.vm.provider(:aws) do |aws, override|
    aws.access_key_id = access_key_id
    aws.secret_access_key = secret_access_key
    aws.keypair_name = keypair

    # Ubuntu LTS 12.04 in us-west-2 with Puppet installed from the Puppet
    # Labs apt repository, with a Docker capable (3.8) Linux kernel
    aws.ami = 'ami-8f89dbbf'
    aws.region = 'us-west-2'
    aws.instance_type = 'm3.xlarge'

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = File.expand_path('~/.ssh/id_rsa')
  end


  %w(base_ubuntu).each do |role|
    config.vm.define(role) do |node|
      node.vm.provider(:aws) do |aws, override|
        aws.tags = {
          :Name => role,
        }
      end

      # This is a Vagrant-local hack to make sure we have properly udpated apt
      # caches since AWS machines are definitely going to have stale ones
      node.vm.provision 'shell',
        :inline => 'if [ ! -f "/apt-cached" ]; then apt-get update && touch /apt-cached; fi'

      # XXX: Temporary hack necessary to make sure we're not locked out of the
      # provisioned machine after the Puppet run complets
      #
      # abayer@ to come up with a better solution in the future
      node.vm.provision 'shell',
        :inline => 'mkdir -p /etc/ssh/ssh_keys && cp /home/ubuntu/.ssh/authorized_keys /etc/ssh/ssh_keys/ubuntu.pub && chown ubuntu /etc/ssh/ssh_keys/ubuntu.pub && chmod 0640 /etc/ssh/ssh_keys/ubuntu.pub'

      node.vm.provision 'puppet' do |puppet|
        puppet.manifest_file = 'site.pp'
        puppet.module_path = ['modules', '3rdParty']
        # Setting the work to /vagrant so our hiera configuration will resolve
        # properly to our relative hieradata/
        puppet.working_directory = '/vagrant'
        puppet.facter = {
          :vagrant => '1',
        }
        puppet.hiera_config_path = 'hiera.vagrant.yaml'
        puppet.options = "--verbose"
      end

      node.vm.provision :serverspec do |spec|
        spec.pattern = "spec/server/#{role}/*.rb"
      end
    end
  end
end

# vim: ft=ruby
