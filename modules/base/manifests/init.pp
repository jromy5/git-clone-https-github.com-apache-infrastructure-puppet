#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages  = hiera('base::basepackages'),
  $pkgprovider = '',
) {


  package { $basepackages: 
    ensure   =>  installed,
  }
}

