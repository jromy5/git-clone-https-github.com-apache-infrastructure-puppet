#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $base_packages  = [],
  $pkgprovider = '',
) {


  package { $base_packages: 
    ensure   =>  installed,
  }
}
