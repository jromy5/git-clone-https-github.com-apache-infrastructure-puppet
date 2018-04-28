#/etc/puppet/modules/pam/install/ubuntu/1404.pp

class pam::install::ubuntu::1404 (
) {

  file { '/etc/pam.d/':
    ensure  => present,
    source  => "puppet:///modules/pam/${::asfosname}/${::asfosrelease}",
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
