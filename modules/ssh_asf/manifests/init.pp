#/etc/puppet/modules/ssh_asf/manifests/init.pp

class ssh_asf {
  $server_opts = hiera_hash('ssh_asf::server_options', {})
  class {'ssh':
    server_options => $server_opts,
  }
}
