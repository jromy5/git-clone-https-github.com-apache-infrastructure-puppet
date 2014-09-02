#/etc/puppet/modules/ldapclient/manifests/init.pp

class ldapclient (
  $ldapclient_packages  = [],
  $pkgprovider          = '',
  $bashpath             = '',
  $ldapcert             = '',
  $ldapservers          = '',
  $nssbinddn            = '',
  $nssbindpasswd        = '',
) {

  package { $ldapclient_packages: 
    ensure   =>  installed,
  }


  class { "ldapclient::install::${asfosname}::${asfosrelease}":
    ldapcert      =>  $ldapcert,
    ldapservers   =>  $ldapservers,
    nssbinddn     =>  $nssbinddn,
    nssbindpasswd =>  $nssbindpasswd,
  }

}
