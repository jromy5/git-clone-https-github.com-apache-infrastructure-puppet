#/etc/puppet/modules/ldapclient/manifests/install/ubuntu/ubuntu_1604.pp

class ldapclient::install::ubuntu::ubuntu_1604 (

  $ldapcert      = '',
  $ldapservers   = '',
  $nssbinddn     = '',
  $nssbindpasswd = '',
  $pamhostcheck  = '',
  $tlscertpath   = '',

) {

  file {
    '/etc/ldap/ldap.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('ldapclient/ldap.conf.erb');
    '/etc/nslcd.conf':
      content => template('ldapclient/nslcd.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      require => File['/etc/ldap.conf'],
      notify  => Service[nslcd];
    '/etc/ldap.conf':
      ensure  => link,
      target  => '/etc/ldap/ldap.conf',
      require => File['/etc/ldap/ldap.conf'];
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
      ensure => directory,
      mode   => '0755';
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
