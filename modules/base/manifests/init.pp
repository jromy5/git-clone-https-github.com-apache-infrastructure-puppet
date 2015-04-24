#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages = [],
  $pkgprovider  = '',
) {

  $packages = hiera_array('base::basepackages', [])

  package { $packages:
    ensure =>  installed,
  }

  $hosts = hiera_hash('base::hosts', {})
  create_resources(host, $hosts)

  $perl_module = hiera_hash('perl::module', {})
  create_resources(perl::module, $perl_module)

  class { "base::install::${asfosname}::${asfosrelease}":
  }
}

<<<<<<< HEAD
<<<<<<< HEAD
=======
 class base::remove_os_install_user (
   $osinstalluser  = undef,
   $osinstallgroup = undef,

) {

    user { "$osinstalluser: 
=======
class base::remove_os_install_user (
  $osinstalluser  = undef,
  $osinstallgroup = undef,

) {

    user { $osinstalluser:
>>>>>>> more linting
      ensure  => absent,
      require => Class['asf999::create_user'],
    }

<<<<<<< HEAD
    group { "$osinstallgroup:
=======
    group { $osinstallgroup:
>>>>>>> more linting
      ensure  => absent,
      require => [User[$osinstalluser], Class['asf999::create_user']],
    }


}

>>>>>>> move the logic to pre-ldap instantiation becuase the default userid for ubuntu is 1000, which conflicts with a valid committers in ldap
# to instantiate defined types (like snmpv3_user) via hiera we need to use
# create_resources to iterate across the hash

class base::snmp::createv3users {
  $v3userhash = hiera_hash('snmp::snmpv3_user',{})
  create_resources(snmp::snmpv3_user, $v3userhash)
}

