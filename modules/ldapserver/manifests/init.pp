#/etc/puppet/modules/ldapserver/manifests/init.pp

class ldapserver (
  $packages         = [],
) {

  package { $packages:
    ensure   =>  installed,
  }

  class { "ldapserver::install::${asfosname}::${asfosrelease}":
  }

}
