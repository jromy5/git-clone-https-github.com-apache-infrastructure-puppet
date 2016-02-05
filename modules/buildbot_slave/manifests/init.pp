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

  # override bwlow in yaml

  $slave_name,
  $slave_password,

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
    'gradle',
    'autoconf',
    'automake',
    'rake',
  ]

  # required packages for slaves

  $slave_packages = [
    'tomcat7',
    'libtool',
    'libpcre3', 
    'libpcre3-dev',
  ]

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
