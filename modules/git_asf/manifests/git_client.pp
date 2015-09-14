#/etc/puppet/modules/git_asf/manifests/git_client.pp

class git_asf::git_client (
) inherits git_asf {

  require git_asf

  package { $git_asf::client_packages:
    ensure => present,
  }

}
