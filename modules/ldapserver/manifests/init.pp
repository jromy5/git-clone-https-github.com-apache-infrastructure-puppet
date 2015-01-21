#/etc/puppet/modules/ldapserver/manifests/init.pp

class ldapserver (
  $packages         = [],
  $slapd_peers      = [],
  $schemas          = [],
  $loglevel         = 'stats',
  $modulepath       = '/usr/lib/ldap',
  $modules          = [],
  $sizelimit        = 'unlimited',
  $backend          = 'mdb',
  $database         = 'mdb',
  $suffix           = 'dc=apache,dc=org',
  $directory        = '/var/lib/ldap',
  $rootdn           = 'cn=root,dc=apache,dc=org',
  $maxsize          = '1024000000',
  $indexes          = [],
  $cafile           = '/etc/ldap/cacerts/cacert.pem',
  $certfile         = '/etc/ldap/cacerts/ldap-wildcard-cert.pem',
  $keyfile          = '/etc/ldap/cacerts/ldap-wildcard-cert.key',

) {

  package { $packages:
    ensure   =>  installed,
  }

  class { "ldapserver::install::${asfosname}::${asfosrelease}":

  }

}
