
class bugzilla (
  $packages       = [],
  $package_ensure = 'latest',
) {

  require apache

  package { $packages:
    ensure  => $package_ensure,
  }


  file { ["/etc/bugzilla", "/etc/bugzilla/.puppet"]:
    ensure => directory,
    mode   => 0755,
    owner  => "root",
    group  => "root",
  }

}
