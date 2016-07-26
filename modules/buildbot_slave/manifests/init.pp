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

  # override below in eyaml

  $slave_name,
  $slave_password,
  $gsr_user,
  $gsr_pw,

){

  # install required packages:

  $bb_basepackages = [
    'buildbot-slave',
    'openjdk-7-jdk',
    'ant',
    'zip',
    'unzip',
    'cmake',
    'doxygen',
    'maven',
    'autoconf',
    'automake',
    'rake',
    'ruby-dev',
    'python3-pip',
    'python3-dev',
    'python3-markdown',
    'libpam0g-dev',
  ]

  # install gradle PPA and gradle 2.x

  apt::ppa { 'ppa:cwchien/gradle':
    ensure => present,
  } ->
  package { 'gradle':
    ensure => latest,
  }

  # merge required packages from hiera for slaves

  $slave_packages = hiera_array('buildbot_slave::required_packages',[])

  package {
    $bb_basepackages:
      ensure => 'present',
  }->

  # slave specific packages defined in hiera

  package {
    $slave_packages:
      ensure => 'present',
  }->

  class { 'oraclejava::install':
    ensure  => 'latest',
    version => '8',
  }->

  # buildbot specific

  group {
    $groupname:
      ensure => $group_present,
      system => true,
  }->

  user {
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
  }->

  # Bootstrap the buildslave service

  exec {
    'bootstrap-buildslave':
      command => "/usr/bin/buildslave create-slave --umask=002 /home/${username}/slave 10.40.0.13:9989 ${slave_name} ${slave_password}",
      creates => "/home/${username}/slave/buildbot.tac",
      user    => $username,
      timeout => 1200,
  }->

  file {
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
  }->

  service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => false,
      hasrestart => true,
      require    => Exec['bootstrap-buildslave'];
  }

}
