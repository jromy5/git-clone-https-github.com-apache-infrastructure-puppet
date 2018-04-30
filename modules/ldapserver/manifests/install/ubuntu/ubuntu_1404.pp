#!/etc/puppet/modules/ldapserver/manifests/install/ubuntu/ubuntu_1404.pp

class ldapserver::install::ubuntu::ubuntu_1404 (

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
  $replcreds        = '',
  $maxsize          = '1024000000',
  $indexes          = [],
  $cafile           = '/etc/ldap/cacerts/cacert.pem',
  $certfile         = '/etc/ldap/cacerts/ldap-wildcard-cert.pem',
  $keyfile          = '/etc/ldap/cacerts/ldap-wildcard-cert.key',
  $cafilecontents   = '',
  $certfilecontents = '',
  $keyfilecontents  = '',
  $backuppath       = '/var/lib/ldap/backup',


) {
  package { $packages:
    ensure   =>  installed,
  }


  file {
    '/etc/ldap/slapd.conf':
      content => template('ldapserver/slapd.conf.erb'),
      # this is needed as new installs make slapd.conf a directory
      force   => true,
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
    "${directory}/accesslog":
      ensure => directory,
      owner  => 'openldap',
      group  => 'openldap',
      mode   => '0750';
    $backuppath:
      ensure => directory,
      owner  => 'openldap',
      group  => 'openldap',
      mode   => '0750';
  }

  service { 'slapd':
    ensure     =>  running,
    hasrestart =>  true,
    hasstatus  =>  true,
  }

  cron {
    'backup-ldap':
      user    => 'root',
      hour    => '1',
      minute  => '51',
      command => "/usr/sbin/slapcat -b dc=apache,dc=org > ${backuppath}/ldap.$(date +\\%Y\\%m\\%d\\%H\\%M).ldif",
      require => File[$backuppath];
    'backup-accesslog':
      user    => 'root',
      hour    => '1',
      minute  => '50',
      command => "/usr/sbin/slapcat -b cn=accesslog > ${backuppath}/accesslog.$(date +\\%Y\\%m\\%d\\%H\\%M).ldif",
      require => File[$backuppath];
  }

  tidy {
    'ldap-backup':
        path    => $backuppath,
        age     => '2d',
        recurse => 1,
        matches => ['ldap.*','accesslog.*'],
  }
}
