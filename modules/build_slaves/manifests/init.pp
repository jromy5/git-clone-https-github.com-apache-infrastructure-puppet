#/etc/puppet/modules/build_slaves/manifests/init.pp

class build_slaves (
  $distro_packages  = [],
  $UserTasksMax     = 49160,
  ) {

  class { "build_slaves::install::${::asfosname}::${::asfosrelease}":
  }

  package {
    $distro_packages:
      ensure => latest,
  }

  python::pip { 'Flask' :
    pkgname => 'Flask';
  }

  python::pip { 'docker-compose' :
    ensure  => 'latest',
    pkgname => 'docker-compose',
  }

  python::pip { 'pip' :
    ensure  => 'latest',
    pkgname => 'pip',
  }

if $::lsbdistrelease == 16.04 {
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

}
