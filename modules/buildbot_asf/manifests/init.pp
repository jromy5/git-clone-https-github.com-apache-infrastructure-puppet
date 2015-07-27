##/etc/puppet/modules/buildbot_asf/manifests/init.pp

class buildbot_asf (

  $uid                           = 8996,
  $gid                           = 8996,
  $group_present                 = 'present',
  $groupname                     = 'buildmaster',
  $groups                        = [],
  $service_ensure                = 'running',
  $service_name                  = 'buildbot',
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'buildmaster',

  # override below in yaml

  # below are contained in eyaml

 $required_packages             =[ 'python-mysqldb' 'buildbot' ],
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

  apt::pin { 'utopic-buildbot':
    ensure   => present,
    priority => 1800,
    packages => 'buildbot',
    codename => 'utopic',
    require  => Apt::Source['utopic'],
    before   => Package['buildbot'],
  }

}
