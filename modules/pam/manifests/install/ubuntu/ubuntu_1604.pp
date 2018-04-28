#/etc/puppet/modules/pam/install/ubuntu/ubuntu_1604.pp

class pam::install::ubuntu::ubuntu_1604 (
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
