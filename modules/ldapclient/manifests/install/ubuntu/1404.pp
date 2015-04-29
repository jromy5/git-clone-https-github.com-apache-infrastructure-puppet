#/etc/puppet/modules/ldapclient/manifests/install/ubuntu/1404.pp

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
    '/etc/nslcd.conf':
      content => template('ldapclient/nslcd.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      notify  => Service[nslcd];
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
      mode    => '0755';
    '/etc/ldap/cacerts/ldap-client.pem':
      content => $ldapcert,
      require => File['/etc/ldap/cacerts'];
  }

    service { 'nslcd':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }
}
