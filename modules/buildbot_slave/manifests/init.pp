##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave (

  $group_present                 = 'present',
  $groupname                     = 'buildslave',
  $groups                        = [],
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'buildslave',
  $required_packages             =[ 'buildbot-slave' ],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# buildbot specific

  user {
    $username:
      ensure     => $user_present,
      system     => true,
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
      ensure => $group_present,
      system => true,
      name   => $groupname,
      gid    => $gid,
  }

# Bootstrap the buildslave service

  exec {
    'bootstrap-buildslave':
      command => "buildslave create-slave /home/${username}/slave 10.40.0.13:9989 bb-slave1 temppw",
      creates => /home/${username}/slave/buildbot.tac,
      timeout => 1200,
  }

}
