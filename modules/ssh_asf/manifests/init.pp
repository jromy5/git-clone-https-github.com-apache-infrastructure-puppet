#/etc/puppet/modules/ssh_asf/manifests/init.pp

class ssh_asf {
  include ssh

  $server_opts = hiera_hash('ssh_asf::server_options', {})
  create_resources(ssh::server_options, $server_opts)

}
