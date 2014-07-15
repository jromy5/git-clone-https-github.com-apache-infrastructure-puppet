#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages  = '',
  $pkgprovider = '',
) {


  package { $basepackages: 
    ensure   =>  installed,
  }
}

