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
  $required_packages             = ['python-mysqldb', 'buildbot'],

  # list of passwords
  $master_list                   = {},

  # override below in yaml
  $buildbot_base_dir             = '',
  $buildmaster_work_dir          = '',
  $connector_port                = '',
  $slave_port_num                = '',
  $mail_from_addr                = '',
  $projectName                   = '',
  $project_url                   = '',
  $change_horizon                = '',
  $build_horizon                 = '',
  $event_horizon                 = '',
  $log_horizon                   = '',
  $build_cache_size              = '',
  $change_cache_size             = '',
  $projects_path                 = '',

  # below are contained in eyaml
  $db_url                        = '',
  $pbcsUser                      = '',
  $pbcsPwd                       = ''

){

  validate_hash($master_list)

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
    ensure   => 'present',
    priority => 1800,
    packages => 'buildbot',
    codename => 'utopic',
    require  => Apt::Source['utopic'],
    before   => Package['buildbot'],
  }

  file { '/x1/${username}/master1/master.cfg':
    ensure  => 'present',
    owner   => $username,
    group   => $groupname,
    content => template('buildbot_asf/master.cfg.erb')
  }

  file { '/x1/${username}/master1/buildbot.tac':
    ensure  => 'present',
    owner   => $username,
    group   => $groupname,
    content => template('buildbot_asf/buildbot.tac.erb')
  }


# various required files

file {
    "/x1/${username}/master1/templates/root.html":
      ensure => 'present',
      mode   => '0664',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/root.html";
    "/x1/${username}/master1/create-master-rat-list.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/create-master-rat-list.sh";
}

# required scripts for cron jobs

file {
    "/x1/${username}/master1/config-update-check.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/config-update-check.sh";
    "/x1/${username}/master1/convert-xml-to-html.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/convert-xml-to-html.sh";
    "/x1/${username}/master1/convert-master-xml-to-html.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/convert-master-xml-to-html.sh";
    "/x1/${username}/master1/create-master-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => "puppet:///modules/buildbot_asf/create-master-index.sh";
}

# cron jobs

  cron {
    'config-update-check':
      user        => $username,
      minute      => '*/5',
      command     => "/x1/${username}/master1/config-update-check.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'convert-xml-to-html':
      user        => $username,
      minute      => '25',
      command     => "/x1/${username}/master1/convert-xml-to-html.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'convert-master-xml-to-html':
      user        => $username,
      minute      => '28',
      command     => "/x1/${username}/master1/convert-master-xml-to-html.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-master-index':
      user        => $username,
      minute      => 30,
      command     => "/x1/${username}/master1/create-master-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username],
}

}
