#/etc/puppet/modules/dovecot/manifests/init.pp

class dovecot (
  $dovecot_packages         = [],
  $dovecot_remove_packages  = [],
  $dovecot_confdir          = '',
  $dovecot_conffile         = '',
  $dovecot_conffile_userdb  = '',
  $dovecot_conffile_passwd  = '',
  $dovecot_ldapuris         = [],
) {

  package { $dovecot_packages:
    ensure => installed,
  }

  package { $dovecot_remove_packages:
    ensure => purged,
  }
  
  file {
    "${dovecot_confdir}":
      ensure => directory,
      owner  => 'root',
      mode   => '0755';
    "${dovecot_confdir}/${dovecot_conffile}":
      source => "puppet://modules/dovecot/${dovecot_conffile}",
      mode   => '0755';
    "${dovecot_confdir}/${dovecot_conffile_userdb}":
      source => "puppet://modules/dovecot/${dovecot_conffile_userdb}",
      mode   => '0755';
    "${dovecot_confdir}/${dovecot_conffile_passdb}":
      source => "puppet://modules/dovecot/${dovecot_conffile_passdb}",
      mode   => '0755';
  }

  class { "dovecot::install::${asfosname}::${asfosrelease}":
  }
