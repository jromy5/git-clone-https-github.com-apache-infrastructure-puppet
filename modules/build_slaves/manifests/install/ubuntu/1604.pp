#/etc/puppet/modules/build_slaves/manifests/install/ubuntu/ubuntu_1604.pp

class build_slaves::install::ubuntu::ubuntu_1604 (


) {

  file { 'logind.conf':
    ensure  => present,
    path    => '/etc/systemd/logind.conf',
    mode    => '0644',
    content => template('build_slaves/logind.conf.erb'),
  }

  service { 'systemd-logind':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/systemd/logind.conf'],
  }
}
