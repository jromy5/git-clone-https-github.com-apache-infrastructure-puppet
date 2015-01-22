
class bugzilla (
) {

  require apache

  file { ["/etc/bugzilla", "/etc/bugzilla/.puppet"]:
    ensure => directory,
    mode   => 0755,
    owner  => "root",
    group  => "root",
  }

}
