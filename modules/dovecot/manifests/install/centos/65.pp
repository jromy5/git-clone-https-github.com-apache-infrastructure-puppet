#/etc/puppet/modules/dovecot/manifests/install/centos/65.pp

class dovecot::install::centos::65 (
  $ldapservers = hiera('ldapclient::ldapservers'),
)
{
  file {
    '/etc/dovecot/dovecot.conf':
      content => template('dovecot/dovecot.conf.erb');
    '/etc/dovecot/dovecot-ldap-userdb.conf.ext':
      content => template('dovecot/dovecot-ldap-userdb.conf.ext.erb'),
      require => File['/etc/dovecot/dovecot.conf'];
    '/etc/dovecot/dovecot-ldap-passdb.conf.ext':
      content => template('dovecot/dovecot-ldap-passdb.conf.ext.erb'),
      require => File['/etc/dovecot/dovecot.conf'];
  }
}
