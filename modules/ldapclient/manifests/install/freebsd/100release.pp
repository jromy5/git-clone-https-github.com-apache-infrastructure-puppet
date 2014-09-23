class ldapclient::install::freebsd::100release (

  $ldapcert      = '',
  $ldapservers   = '',
  $nssbinddn     = '',
  $nssbindpasswd = '',
  $pamhostcheck  = '',
  $tlscertpath   = '',

) {

  file { 
    '/usr/local/etc/openldap/ldap.conf':
      content => template('/usr/local/etc/puppet/modules/ldapclient/templates/openldap_ldap.conf.erb');
    '/usr/local/etc/ldap.conf':
      content => template('/usr/local/etc/puppet/modules/ldapclient/templates/ldap.conf.erb');
    '/usr/local/etc/nss_ldap.conf':
      ensure  => link,
      target  => '/usr/local/etc/ldap.conf',
      require => File['/usr/local/etc/ldap.conf'];
    '/etc/nsswitch.conf':
      source  => 'puppet:///modules/ldapclient/etc/nsswitch.conf',
      require => File['/usr/local/etc/ldap.conf'];
    '/usr/local/etc/openldap/cacerts':
      ensure  => directory,
      mode    => 755;
    '/usr/local/etc/openldap/cacerts/ldap-client.pem':
      source  =>  'puppet:///modules/ldapclient/etc/ldap-client.pem',
      require =>  File['/etc/ldap/cacerts'];
  }

}
