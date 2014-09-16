class dovecot::install::ubuntu::1404 (
  $ldapservers = '',
)
{
  file {
    '/etc/dovecot/dovecot.conf':
      content => template('dovecot/dovecot.conf.erb');
    '/etc/dovecot/dovecot-ldap-userdb.ext.conf':
      content => template('dovecot/dovecot-ldap-userdb.ext.conf.erb'),
      require => File['/etc/dovecot/dovecot.conf'];
    '/etc/dovecot/dovecot-ldap-passdb.ext.conf':
      content => template('dovecot/dovecot-ldap-passdb.ext.conf.erb'),
      require => File['/etc/dovecot/dovecot.conf'];
  }
}
