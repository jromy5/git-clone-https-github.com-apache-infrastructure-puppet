#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages = [],
  $pkgprovider  = '',
) {

  $packages = hiera_array('base::basepackages', [])

  package { $packages:
    ensure   =>  installed,
  }

  $hosts = hiera_hash('base::hosts', {})
  create_resources(host, $hosts)

  $perl_module = hiera_hash('perl::module', {})
  create_resources(perl::module, $perl_module)

  class { "base::install::${asfosname}::${asfosrelease}":
  }
}

# to instantiate defined types (like snmpv3_user) via hiera we need to use
# create_resources to iterate across the hash

class base::snmp::createv3users {
  $v3userhash = hiera_hash('snmp::snmpv3_user',{})
  create_resources(snmp::snmpv3_user, $v3userhash)
}

