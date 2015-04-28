#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages = [],
  $pkgprovider  = '',
) {

  $packages = hiera_array('base::basepackages', [])

  package { $packages:
    ensure =>  installed,
  }

  $hosts = hiera_hash('base::hosts', {})
  create_resources(host, $hosts)

  $perl_module = hiera_hash('perl::module', {})
  create_resources(perl::module, $perl_module)

  class { "base::install::${asfosname}::${asfosrelease}":
  }
}
