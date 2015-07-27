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
$buildbot_base_dir               = ''
$buildmaster_work_dir            = ''
$connector_port                  = ''
$slave_port_num                  = ''
$mail_from_addr                  = ''
$projectName                     = ''
$project_url                     = ''
$change_horizon                  = ''
$build_horizon                   = ''
$event_horizon                   = ''
$log_horizon                     = ''
$build_cache_size                = ''
$change_cache_size               = ''
$projects_path                   = ''    

  # below are contained in eyaml

$db_url                          = ''
$pbchangesource_user             = ''
$pchangesource_pass              = ''

 $required_packages              =[ 'python-mysqldb' 'buildbot' ],
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
