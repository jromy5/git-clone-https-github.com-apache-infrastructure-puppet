#/etc/puppet/modules/ldapserver/manifests/init.pp

class ldapserver (
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

) {

  package { $packages:
    ensure   =>  installed,
  }

  class { "ldapserver::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
    slapd_peers      => $slapd_peers,
    schemas          => $schemas,
    ldaploglevel     => $ldaploglevel,
    modulepath       => $modulepath,
    modules          => $modules,
    sizelimit        => $sizelimit,
    backend          => $backend,
    database         => $database,
    suffix           => $suffix,
    directory        => $directory,
    rootdn           => $rootdn,
    rootpw           => $rootpw,
    replcreds        => $replcreds,
    maxsize          => $maxsize,
    indexes          => $indexes,
    cafile           => $cafile,
    certfile         => $certfile,
    keyfile          => $keyfile,
    cafilecontents   => $cafilecontents,
    certfilecontents => $certfilecontents,
    keyfilecontents  => $keyfilecontents,

  }

}
