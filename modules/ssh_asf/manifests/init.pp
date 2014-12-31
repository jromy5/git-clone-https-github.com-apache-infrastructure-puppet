#/etc/puppet/modules/ssh_asf/manifests/init.pp

class ssh_asf {
  include ssh

  $server_opts = hiera('ssh_asf::server_options', {})
  notice("server_opts: ${server_opts}")
  create_resources(ssh::server_options, $server_opts)

}
