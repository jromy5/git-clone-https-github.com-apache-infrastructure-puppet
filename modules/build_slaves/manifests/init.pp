#/etc/puppet/modules/build_slaves/manifests/init.pp

class build_slaves (
  $distro_packages  = [],
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

  exec { 'raise-UserTasksMax':
    command => '/bin/sed -i /\#User/d /etc/systemd/logind.conf && /bin/echo UserTasksMax=49152 >> /etc/systemd/logind.conf',
    onlyif  => '/usr/bin/test `/bin/grep -c UserTasksMax=49152 /etc/systemd/logind.conf` -eq 0'
  }

}
