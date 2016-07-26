#/etc/puppet/modules/ldapclient/manfiests/install/centos/65.pp

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
      ensure => directory,
      mode   => '0755';
    $tlscertpath:
      content => $ldapcert,
      require => File['/etc/openldap/cacerts'];
  }

  exec { "/usr/sbin/authconfig --enableldap --enableldapauth --enabletls --ldapbasedn='${::nssbasedn}' --ldapserver='${ldapservers}' --ldaploadcacert=file:///${tlscertpath} --update":
        unless  => '/bin/grep -qr ldap /etc/pam.d',
        require => File[$tlscertpath],
      }

}
