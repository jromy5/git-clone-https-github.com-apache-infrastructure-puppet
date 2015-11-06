##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave (

  $group_present                 = 'present',
  $groupname                     = 'buildslave',
  $groups                        = [],
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'buildslave',


# buildbot specific

  user {
    $username:
      system     => true,
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

  group {
    $groupname:
      system     => true,
      ensure => $group_present,
      name   => $groupname,
      gid    => $gid,
}

}
