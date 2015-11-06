##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave (

  $system                        = true,
  $group_present                 = 'present',
  $groupname                     = 'buildslave',
  $groups                        = [],
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'buildslave',


# buildbot specific

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "/x1/${username}",
      shell      => $shell,
      uid        => $uid,
      gid        => $groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
  }

  group {
    $groupname:
      ensure => $group_present,
      name   => $groupname,
      gid    => $gid,
}

  apt::source { 'utopic':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'utopic',
    repos    => 'main',
  }

  apt::source { 'utopic-updates':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'utopic-updates',
    repos    => 'main',
  }

}
