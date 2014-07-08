#/etc/puppet/modules/sudoers/manifests/init.pp

class sudoers (
  $sudoers_packages  = [],
  $pkgprovider = '',
  $sudoers_file = '',
  $sudoers_template = '',
) {

  package { $sudoers_packages: 
    ensure   =>  installed,
  }

  class { "sudoers::install::${asf_osname}::${asf_osrelease}":
  }


}
