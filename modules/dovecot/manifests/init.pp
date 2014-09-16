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
  
  file {
    "/etc/dovecot":
      ensure => directory,
      owner  => 'root',
      mode   => '0755',
  }

  class { "dovecot::install::${asfosname}::${asfosrelease}":
    ldapservers => $ldapservers,
  }
