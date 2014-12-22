class ldapclient::install::centos::65 (

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
    '/etc/openldap/ldap.conf':
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
    '/etc/openldap/cacerts':
      ensure  => directory,
      mode    => 755;
    '/etc/openldap/cacerts/ldap-client.pem':
      content  =>  $ldapcert,
      require =>  File['/etc/openldap/cacerts'];
  }

}
