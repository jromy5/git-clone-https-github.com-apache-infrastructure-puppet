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

  class { "base::remove_os_install_user": 
  }

  class { "base::install::${asfosname}::${asfosrelease}":
  }
}

 class base::remove_os_install_user (
   $osinstalluser  = undef,
   $osinstallgroup = undef,

) {

<<<<<<< HEAD
    user { "$osinstalluser: 
=======
    user { "$osinstalluser": 
>>>>>>> deployment
      ensure  => absent,
      require => Class['asf999::create_user'],
    }

<<<<<<< HEAD
    group { "$osinstallgroup:
=======
    group { "$osinstallgroup":
>>>>>>> deployment
      ensure  => absent,
      require => [User["$osinstalluser"], Class['asf999::create_user']],
    }


}

# to instantiate defined types (like snmpv3_user) via hiera we need to use
# create_resources to iterate across the hash

class base::snmp::createv3users {
  $v3userhash = hiera_hash('snmp::snmpv3_user',{})
  create_resources(snmp::snmpv3_user, $v3userhash)
}

