class ldapclient::install::ubuntu::1404 (

  $ldapcert     = '',
  $pamhostcheck = '',
  $tlscertpath  = '',

) {

  file { 
    '/etc/ldap.conf':
      content => template('ldapclient/ldap.conf.erb');
    '/usr/local/etc/nss_ldap.conf':
      ensure  => link,
      target  => '/usr/local/etc/ldap.conf',
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
