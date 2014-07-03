#/etc/puppet/modules/ldapclient/manifests/init.pp

class ldapclient (
  $ldapclient_packages  = [],
  $pkgprovider          = '',
  $bashpath             = '',
  $ldapcert             = '',
) {

  package { $ldapclient_packages: 
    ensure   =>  installed,
  }


  class { "ldapclient::install::${asf_osname}::${asf_osrelease}":
    ldapcert   =>  $ldapcert,
  }

}
