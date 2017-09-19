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
    pkgname       => 'Flask';
  }

  python::pip { 'docker-compose' :
    pkgname       => 'docker-compose';
  }

}
