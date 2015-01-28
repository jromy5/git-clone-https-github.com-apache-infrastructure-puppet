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

) { 
  package { $packages:
    ensure   =>  installed,
  }


  file { 
    '/etc/ldap/slapd.conf': 
      content   => template('ldapserver/slapd.conf.erb'), 
      require   => Package["$packages"],
      notify    => Service["slapd"];
    '/etc/default/slapd':
      source    => "puppet:///modules/ldapserver/default-slapd",
      owner     => 'root',
      mode      => '0644',
      ensure    => present,
      require   => Package['slapd'],
      notify    => Service['slapd'];
   }


   service { 'slapd':
     hasrestart   =>  true,
     hasstatus    =>  true,
     ensure       =>  running,
   }
}
