#/etc/puppet/modules/build_slaves/manifests/init.pp

class build_slaves (
  $distro_packages  = [],
  $UserTasksMax     = 49168,
  $username = 'jenkins',
  $groupname = 'jenkins',
  ) {

  class { "build_slaves::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
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

}
