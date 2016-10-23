#/etc/puppet/modules/build_slaves/manifests/init.pp

class build_slaves (
  $distro_packages  = [],
  ) {

  class { "build_slaves::install::${::asfosname}::${::asfosrelease}":
  }

  exec { 'Add nodesource-6 sources':
    command => 'if [ ! -f /etc/apt/sources.list.d/nodesource.list ] ; then curl https://deb.nodesource.com/setup_6.x ; fi | bash -',
    creates => '/etc/apt/sources.list.d/nodesource.list',
    path    => ['/usr/bin', '/bin', '/usr/sbin']
  }

  package {
    $distro_packages:
      ensure => installed,
  }

  python::pip { 'Flask' :
    pkgname       => 'Flask';
  }

}
