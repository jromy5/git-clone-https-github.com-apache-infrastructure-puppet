# class to manage buildbot master via python venv

class buildbot_asf (
  $username             = 'buildmaster',
  $groupname            = 'buildmaster',
  $venv_dir             = "/x1/buildmaster",

  $bb_version           = '0.8.14',

  # list of passwords from eyaml

  $master_list          = {},

  $buildbot_base_dir    = '.',
  $buildmaster_work_dir = 'master1',
  $connector_port       = '8080',
  $slave_port_num       = '9989',
  $mail_from_addr       = 'buildbot@apache.org',
  $projectName          = 'ASF Buildbot',
  $project_url          = 'https://ci.apache.org/',
  $change_horizon       = '200',
  $build_horizon        = '100',
  $event_horizon        = '50',
  $log_horizon          = '40',
  $build_cache_size     = '50',
  $change_cache_size    = '10000',
  $projects_path        = "/x1/buildmaster/master1/projects",

  # below are contained in eyaml

  $db_url               = '',
  $pbcsUser             = '',
  $pbcsPwd              = ''

){

  # pip install buildbot into a venv. this approach will make for a
  # more modular install and allow for future upgrades beyond an OS
  # supported version

  # set bb_version to install that version of the buildbot pip and
  # its dependencies.

  group { $groupname:
    ensure => present,
    name   => $groupname,
    system => true,
  }

  user { $username:
    ensure     => present,
    name       => $username,
    shell      => '/bin/bash',
    require    => Group[$groupname],
    system     => true,
    home       => $venv_dir,
    managehome => false,
  }

  python::virtualenv { 'buildbot':
    ensure   => 'present',
    version  => 'system',
    owner    => $username,
    group    => $groupname,
    venv_dir => $venv_dir,
  }

  # pip install bb manually due to puppet3 limitations

  exec { 'install buildbot':
    environment => [ "VIRTUAL_ENV=$venv_dir" ],
    command     => "$venv_dir/bin/pip install buildbot==$bb_version",
    cwd         => "$venv_dir",
    user        => $username,
    group       => $groupname,
    require     => Python::Virtualenv[buildbot],
  }

  # populate buildmaster's .profile to activate the venv

  file {
    "$venv_dir/.profile":
      ensure  => present,
      mode    => '0755',
      owner   => $username,
      group   => $groupname,
      content => template('buildbot_asf/profile.erb');
    "$venv_dir/master1/master.cfg":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      notify  => Exec['buildbot-reconfig'],
      content => template('buildbot_asf/master.cfg.erb');
    "$venv_dir/master1/buildbot.tac":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      content => template('buildbot_asf/buildbot.tac.erb');
    "$venv_dir/master1/private.py":
      ensure  => 'present',
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      content => template('buildbot_asf/private.py.erb');

    # template files and html

    "$venv_dir/master1/templates":
      ensure => 'directory',
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "$venv_dir/master1/templates/root.html":
      ensure => 'present',
      mode   => '0664',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/root.html';
    "$venv_dir/master1/public_html/asf_logo_wide_2016.png":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/asf_logo_wide_2016.png';
    "$venv_dir/master1/public_html/bg_gradient.jpg":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/bg_gradient.jpg';
    "$venv_dir/master1/public_html/default.css":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/default.css';
    "$venv_dir/master1/public_html/favicon.ico":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/favicon.ico';
    "$venv_dir/master1/public_html/style.css":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/style.css';
    "$venv_dir/master1/public_html/robots.txt":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/robots.txt';
    "$venv_dir/master1/public_html/sitemap-index.xml":
      ensure => 'present',
      mode   => '0644',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/sitemap-index.xml';

    # configscanner daemon

    '/etc/systemd/system/configscanner.service':
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/configscanner.ubuntu';
    "$venv_dir/master1/configscanner.py":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/configscanner.py';

    # required scripts for cron jobs

    "$venv_dir/master1/config-update-check.sh":
      ensure => 'absent',
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "$venv_dir/master1/create-master-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/create-master-index.sh';
    "$venv_dir/master1/public_html/projects/openoffice/":
      ensure => 'directory',
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "$venv_dir/master1/public_html/projects/openoffice/create-ooo-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/create-ooo-snapshots-index.sh';
    "$venv_dir/master1/public_html/projects/xmlgraphics/fop/create-fop-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-fop-snapshots-index.sh';
    "$venv_dir/master1/public_html/projects/xmlgraphics/batik/create-batik-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-batik-snapshots-index.sh';
    "$venv_dir/master1/public_html/projects/xmlgraphics/commons/create-commons-snapshots-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-commons-snapshots-index.sh';
    "$venv_dir/master1/public_html/projects/subversion/nightlies/create-subversion-nightlies-index.sh":
      ensure => 'present',
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/buildbot_asf/projects/create-subversion-nightlies-index.sh';
  }

  # cron jobs

  cron {
    'create-master-index':
      user        => $username,
      minute      => 30,
      command     => "$venv_dir/master1/create-master-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-ooo-snapshots-index':
      user        => $username,
      minute      => 40,
      hour        => 5,
      command     => "$venv_dir/master1/public_html/projects/openoffice/create-ooo-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-fop-snapshots-index':
      user        => $username,
      minute      => '10',
      hour        => '10',
      command     => "$venv_dir/master1/public_html/projects/xmlgraphics/fop/create-fop-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-batik-snapshots-index':
      user        => $username,
      minute      => '15',
      hour        => '10',
      command     => "$venv_dir/master1/public_html/projects/xmlgraphics/batik/create-batik-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-commons-snapshots-index':
      user        => $username,
      minute      => '20',
      hour        => '10',
      command     => "$venv_dir/master1/public_html/projects/xmlgraphics/commons/create-commons-snapshots-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'create-subversion-nightlies-index':
      user        => $username,
      minute      => '5',
      hour        => '4',
      command     => "$venv_dir/master1/public_html/projects/subversion/nightlies/create-subversion-nightlies-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
  }

  exec {
    'buildbot-reconfig':
      command     => "$venv_dir/bin/buildbot reconfig $venv_dir/master1",
      onlyif      => "$venv_dir/bin/buildbot checkconfig $venv_dir/master1",
      refreshonly => true,
  }

  # Buildbot config scanner app

  service { 'configscanner':
    ensure    => 'running',
    enable    => true,
    hasstatus => true,
    subscribe => File['/x1/buildmaster/master1/configscanner.py'],
  }

}
