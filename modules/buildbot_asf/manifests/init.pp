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

  file {
    "/x1/${username}/master1/master.cfg":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      notify  => Exec['buildbot-reconfig'],
      content => template('buildbot_asf/master.cfg.erb');

    "/x1/${username}/master1/buildbot.tac":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      content => template('buildbot_asf/buildbot.tac.erb');

    "/x1/${username}/master1/private.py":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      content => template('buildbot_asf/private.py.erb');

# various required files

    "/x1/${username}/master1/templates/root.html":
      ensure => 'present',
      mode   => '0664',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/root.html';
    "/x1/${username}/master1/create-master-rat-list.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/create-master-rat-list.sh';
    "/x1/${username}/master1/public_html/asf_logo_wide_2016.png":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/asf_logo_wide_2016.png';

# required scripts for cron jobs

    "/x1/${username}/master1/config-update-check.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/config-update-check.sh';
    "/x1/${username}/master1/convert-xml-to-html.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/convert-xml-to-html.sh';
    "/x1/${username}/master1/convert-master-xml-to-html.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/convert-master-xml-to-html.sh';
    "/x1/${username}/master1/create-master-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/create-master-index.sh';
    "/x1/${username}/master1/public_html/projects/openoffice/":
      ensure => 'directory',
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "/x1/${username}/master1/public_html/projects/openoffice/create-ooo-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/create-ooo-snapshots-index.sh';
    "/x1/${username}/master1/public_html/projects/ofbiz/create-ofbiz-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-ofbiz-snapshots-index.sh';
    "/x1/${username}/master1/public_html/projects/ofbiz/create-ofbiz-archives-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-ofbiz-archives-index.sh';
    "/x1/${username}/master1/public_html/projects/ofbiz/archive-snapshots-monthly.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/archive-snapshots-monthly.sh';
    "/x1/${username}/master1/public_html/projects/ofbiz/remove-snapshots-daily.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/projects/remove-snapshots-daily.sh';
    "/x1/${username}/master1/public_html/projects/fop/create-fop-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-fop-snapshots-index.sh';
    "/x1/${username}/master1/public_html/projects/subversion/nightlies/create-subversion-nightlies-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-subversion-nightlies-index.sh';
    "/x1/${username}/master1/public_html/projects/jmeter/nightlies/create-jmeter-nightlies-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-jmeter-nightlies-index.sh';
  }

# cron jobs

  cron {
    'config-update-check':
      user        => $username,
      minute      => '*/5',
      command     => "/x1/${username}/master1/config-update-check.sh  > /dev/null 2>&1",
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
      command     => "/x1/${username}/master1/convert-master-xml-to-html.sh > /dev/null 2>&1",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-master-index':
      user        => $username,
      minute      => 30,
      command     => "/x1/${username}/master1/create-master-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-ooo-snapshots-index':
      user        => $username,
      minute      => 40,
      hour        => 5,
      command     => "/x1/${username}/master1/public_html/projects/openoffice/create-ooo-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-ofbiz-snapshots-index':
      user        => $username,
      minute      => '31',
      command     => "/x1/${username}/master1/public_html/projects/ofbiz/create-ofbiz-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-ofbiz-archives-index':
      user        => $username,
      minute      => '32',
      command     => "/x1/${username}/master1/public_html/projects/ofbiz/create-ofbiz-archives-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'archive-snapshots-monthly':
      user        => $username,
      minute      => '1',
      hour        => '0',
      month       => '1',
      command     => "/x1/${username}/master1/public_html/projects/ofbiz/archive-snapshots-monthly.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'remove-snapshots-daily':
      user        => $username,
      minute      => '5',
      hour        => '0',
      command     => "/x1/${username}/master1/public_html/projects/ofbiz/remove-snapshots-daily.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-fop-snapshots-index':
      user        => $username,
      minute      => '10',
      hour        => '10',
      command     => "/x1/${username}/master1/public_html/projects/fop/create-fop-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-subversion-nightlies-index':
      user        => $username,
      minute      => '5',
      hour        => '4',
      command     => "/x1/${username}/master1/public_html/projects/subversion/nightlies/create-subversion-nightlies-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-jmeter-nightlies-index':
      user        => $username,
      minute      => '5',
      hour        => '5',
      command     => "/x1/${username}/master1/public_html/projects/jmeter/nightlies/create-jmeter-nightlies-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
  }

# execs

  exec {
    'buildbot-reconfig':
      command => "/usr/bin/buildbot /x1/${username}/master1 reconfig",
      onlyif => "/usr/bin/buildbot /x1/${username}/master1 checkconfig",
      refreshonly => true,
}

}
