#/etc/puppet/modules/dovecot/manifests/init.pp

class dovecot (
  $dovecot_packages         = [],
  $dovecot_remove_packages  = [],
) {

  package { $dovecot_packages:
    ensure => installed,
  }

  package { $dovecot_remove_packages:
    ensure => purged,
  }

  class { "dovecot::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
    ldapservers => $ldapservers, # lint:ignore:variable_scope
  }
}
