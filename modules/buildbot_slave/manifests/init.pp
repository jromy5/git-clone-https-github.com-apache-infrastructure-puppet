##/etc/puppet/modules/buildbot_slave/manifests/init.pp

class buildbot_slave (

  $group_present     = 'present',
  $groupname         = 'buildslave',
  $groups            = [],
  $shell             = '/bin/bash',
  $user_present      = 'present',
  $username          = 'buildslave',
  $service_ensure    = 'running',
  $service_name      = 'buildslave',
  $gradle_versions   = ['3.5', '4.3', '4.3.1'],

  # override below in eyaml

  $slave_name,
  $slave_password,
  $gsr_user,
  $gsr_pw,
  $nexus_password = '',
  $npmrc_password = '',
  $bb_basepackages = [],

){

  include buildbot_slave::buildbot

  # install gradle PPA and gradle 2.x

  apt::ppa { 'ppa:cwchien/gradle':
    ensure => present,
  }
  -> package { 'gradle':
    ensure => latest,
  }

  # define gradle symlinking.
  define buildbot_slaves::symlink_gradle ($versions = $title) {
    package {"gradle-${versions}":
      ensure => latest,
    }
  }

  buildbot_slaves::symlink_gradle { $gradle_versions: }



  python::pip { 'Flask':
    pkgname => 'Flask';
  }

  # merge required packages from hiera for slaves

  $slave_packages = hiera_array('buildbot_slave::required_packages',[])

  package {
    $bb_basepackages:
      ensure => 'present',
  }
  -> package {
    $slave_packages:
      ensure => 'present',
  }
  -> class { 'oraclejava::install':
    ensure  => 'latest',
    version => '8',
  }
  -> group {
    $groupname:
      ensure => $group_present,
      system => true,
  }
  -> user {
    $username:
      ensure     => $user_present,
      system     => true,
      name       => $username,
      home       => "/home/${username}",
      shell      => $shell,
      gid        => $groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
  }
  -> exec {
    'bootstrap-buildslave':
      command => "/usr/bin/buildslave create-slave --umask=002 /home/${username}/slave 10.40.0.13:9989 ${slave_name} ${slave_password}",
      creates => "/home/${username}/slave/buildbot.tac",
      user    => $username,
      timeout => 1200,
  }
  -> file {
    "/home/${username}/.git-credentials":
      content => template('buildbot_slave/git-credentials.erb'),
      mode    => '0640',
      owner   => $username,
      group   => $groupname;

    "/home/${username}/.gitconfig":
      ensure => 'present',
      source => 'puppet:///modules/buildbot_slave/gitconfig',
      mode   => '0644',
      owner  => $username,
      group  => $groupname;

    "/home/${username}/.m2":
      ensure  => directory,
      require => User[$username],
      owner   => $username,
      group   => $groupname,
      mode    => '0755';

    "/home/${username}/.gradle":
      ensure  => directory,
      require => User[$username],
      owner   => $username,
      group   => $groupname,
      mode    => '0755';

    "/home/${username}/.puppet-lint.rc":
      require => User[$username],
      path    => "/home/${username}/.puppet-lint.rc",
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      source  => 'puppet:///modules/buildbot_slave/.puppet-lint.rc';

    "/home/${username}/.m2/settings.xml":
      require => File["/home/${username}/.m2"],
      path    => "/home/${username}/.m2/settings.xml",
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      content => template('buildbot_slave/m2_settings.erb');

    "/home/${username}/.m2/toolchains.xml":
      require => File["/home/${username}/.m2"],
      path    => "/home/${username}/.m2/toolchains.xml",
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      source  => 'puppet:///modules/buildbot_slave/toolchains.xml';

    "/home/${username}/.gradle/gradle.properties":
      require => File["/home/${username}/.gradle"],
      path    => "/home/${username}/.gradle/gradle.properties",
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      content => template('buildbot_slave/gradle_properties.erb');

    "/home/${username}/.ssh":
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      mode    => '0700',
      require => User[$username];

    "/home/${username}/.ssh/config":
      require => File["/home/${username}/.ssh"],
      path    => "/home/${username}/.ssh/config",
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      source  => 'puppet:///modules/buildbot_slave/ssh/config';

    "/home/${username}/slave":
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      require => Exec['bootstrap-buildslave'];

    "/home/${username}/slave/buildbot.tac":
      content => template('buildbot_slave/buildbot.tac.erb'),
      mode    => '0644',
      notify  => Service[$service_name],
      require => Exec['bootstrap-buildslave'];

    "/home/${username}/slave/private.py":
      content => template('buildbot_slave/private.py.erb'),
      owner   => $username,
      mode    => '0640',
      notify  => Service[$service_name],
      require => Exec['bootstrap-buildslave'];

    "/home/${username}/slave/info/host":
      content => template('buildbot_slave/host.erb'),
      mode    => '0644',
      require => Exec['bootstrap-buildslave'];

    "/home/${username}/slave/info/admin":
      content => template('buildbot_slave/admin.erb'),
      mode    => '0644',
      require => Exec['bootstrap-buildslave'];
  }
  -> service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => false,
      hasrestart => true,
      require    => Exec['bootstrap-buildslave'];
  }

}
