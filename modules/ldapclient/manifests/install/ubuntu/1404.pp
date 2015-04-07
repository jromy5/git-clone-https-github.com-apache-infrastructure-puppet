class ldapclient::install::ubuntu::1404 (

  $ldapcert      = '',
  $ldapservers   = '',
  $nssbinddn     = '',
  $nssbindpasswd = '',
  $pamhostcheck  = '',
  $tlscertpath   = '',

) {

  file { 
    '/etc/ldap.conf':
      content => template('ldapclient/ldap.conf.erb');
    '/etc/ldap/ldap.conf':
      ensure  => link,
      target  => '/etc/ldap.conf',
      require => File['/etc/ldap.conf'];
    '/etc/nss-ldapd.conf':
      ensure  => link,
      target  => '/etc/ldap.conf',
      require => File['/etc/ldap.conf'];
    '/etc/nss_ldap.conf':
      ensure  => link,
      target  => '/etc/ldap.conf',
      require => File['/etc/ldap.conf'];
    '/etc/nsswitch.conf':
      source  => 'puppet:///modules/ldapclient/etc/nsswitch.conf',
      require => File['/etc/ldap.conf'];
    '/etc/ldap/cacerts':
      ensure  => directory,
      mode    => 755;
    '/etc/ldap/cacerts/ldap-client.pem':
      content  =>  $ldapcert,
      require =>  File['/etc/ldap/cacerts'];
  }

}
