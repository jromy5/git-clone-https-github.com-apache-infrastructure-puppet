#/etc/puppet/modules/apbackup/manifests/init.pp

class apbackup (
  $uid           = 511,
  $gid           = 511,
  $group_present = 'present',
  $groupname     = 'apbackup',
  $groups        = [],
  $shell         = '/bin/bash',
  $user_present  = 'present',
  $username      = 'apbackup',
) {

   user { "${username}":
        name       => "${username}",
        ensure     => "${user_present}",
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
        ensure => "${group_present}",
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
