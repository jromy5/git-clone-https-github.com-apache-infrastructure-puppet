#/etc/puppet/modules/apbackup/manifests/init.pp

class apbackup (
  $uid            = 511,
  $gid            = 511,
  $groupname      = 'apbackup',
  $groups         = [],
  $shell          = '/bin/bash',
  $username       = 'apbackup',
) {

   user { "${username}":
        name       => "${username}",
        ensure     => present,
        home       => "/home/${username}",
        shell      => "${shell}",
        uid        => "${uid}",
        gid        => "${groupname}",
        groups     => $groups,
        managehome => true,
        require    => Group["${groupname}"],
    }

    group { "${groupname}":
        name   => "${groupname}",
        ensure => present,
        gid    => "${gid}",
    }

    file { 'apbackup profile': 
        path    => "/home/${username}/.profile",
        ensure  => 'present',
        mode    => '0644',
        owner   => "${username}",
        group   => "${groupname}",
        source  => 'puppet:///modules/apbackup/home/profile',
        require => User["${username}"],
    }
}
