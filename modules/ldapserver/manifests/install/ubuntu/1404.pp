#!/etc/puppet/modules/ldapserver/manifests/install/ubuntu/1404.pp

class ldapserver::install::ubuntu::1404 (

  $packages         = [],
  $slapd_peers      = [],
  $schemas          = [],
  $ldaploglevel     = 'stats',
  $modulepath       = '/usr/lib/ldap',
  $modules          = [],
  $sizelimit        = 'unlimited',
  $backend          = 'mdb',
  $database         = 'mdb',
  $suffix           = 'dc=apache,dc=org',
  $directory        = '/var/lib/ldap',
  $rootdn           = 'cn=root,dc=apache,dc=org',
  $rootpw           = '',
  $maxsize          = '1024000000',
  $indexes          = [],
  $cafile           = '/etc/ldap/cacerts/cacert.pem',
  $certfile         = '/etc/ldap/cacerts/ldap-wildcard-cert.pem',
  $keyfile          = '/etc/ldap/cacerts/ldap-wildcard-cert.key',
  $cafilecontents   = '',
  $certfilecontents = '',
  $keyfilecontents  = '',


) {
  package { $packages:
    ensure   =>  installed,
  }


  file {
    '/etc/ldap/slapd.conf':
      content => template('ldapserver/slapd.conf.erb'),
      force   => true, # this is needed as new installs make slapd.conf a directory
      require => Package['slapd'],
      notify  => Service['slapd'];
    '/etc/ldap/slapd.d':
      ensure => absent,
      force  => true; # this isn't needed by our install
    '/etc/ldap/schema/asf-custom.schema':
      ensure  => present,
      source  => 'puppet:///modules/ldapserver/asf-custom.schema',
      owner   => 'root',
      mode    => '0644',
      require => Package['slapd'],
      notify  => Service['slapd'];
    '/etc/ldap/schema/openssh-lpk.schema':
      ensure  => present,
      source  => 'puppet:///modules/ldapserver/openssh-lpk.schema',
      owner   => 'root',
      mode    => '0644',
      require => Package['slapd'],
      notify  => Service['slapd'];
    '/etc/default/slapd':
      ensure  => present,
      source  => 'puppet:///modules/ldapserver/default-slapd',
      owner   => 'root',
      mode    => '0644',
      require => Package['slapd'],
      notify  => Service['slapd'];
    $cafile:
      content => $cafilecontents,
      require => File['/etc/ldap/cacerts'],
      owner   => root,
      mode    => '0644',
      notify  => Service['slapd'];
    $certfile:
      content => $certfilecontents,
      require => [File['/etc/ldap/cacerts'],Package['slapd']],
      owner   => openldap,
      mode    => '0600',
      notify  => Service['slapd'];
    $keyfile:
      content => $keyfilecontents,
      require => [File['/etc/ldap/cacerts'],Package['slapd']],
      owner   => openldap,
      mode    => '0600',
      notify  => Service['slapd'];
  }

  service { 'slapd':
    ensure     =>  running,
    hasrestart =>  true,
    hasstatus  =>  true,
  }
}
