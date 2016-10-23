#/etc/puppet/modules/build_slaves/manifests/init.pp

include python

class build_slaves (
  $distro_packages  = [],
  ) {

  class { "build_slaves::install::${::asfosname}::${::asfosrelease}":
  }

  package {
    $distro_packages:
      ensure => installed,
  }

  class { 'python' :
    version    => 'system',
    pip        => 'present',
    dev        => 'absent',
    virtualenv => 'present',
    gunicorn   => 'absent',
  }

  python::pip { 'Flask' :
    pkgname       => 'Flask';
  }

}
