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

  user { $username:
    ensure     => $user_present,
    name       => $username,
    home       => "/home/${username}",
    shell      => $shell,
    uid        => $uid,
    gid        => $groupname,
    groups     => $groups,
    managehome => true,
    require    => Group[$groupname],
  }

  group { $groupname:
    ensure => $group_present,
    name   => $groupname,
    gid    => $gid,
  }

  file { 'apbackup profile':
    ensure  => 'present',
    path    => "/home/${username}/.profile",
    mode    => '0644',
    owner   => $username,
    group   => $groupname,
    source  => 'puppet:///modules/apbackup/home/profile',
    require => User[$username],
  }
}
