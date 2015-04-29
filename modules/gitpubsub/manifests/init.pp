#/etc/puppet/gitpubsub/manifests/init.pp

class gitpubsub (
  $uid            = 9993,
  $gid            = 9993,
  $conf_path      = '/usr/local/etc/gitpubsub',
  $conf_file      = 'gitpubsub.cfg',
  $group_present  = 'present',
  $groupname      = 'gitpubsub',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'gitpubsub',
  $shell          = '/bin/bash',
  $source         = 'gitpubsub.cfg',
  $user_present   = 'present',
  $username       = 'gitpubsub',

){

  package { [ 'lua5.2', 'lua-filesystem', 'lua-socket'] :
    ensure => installed
  }

  user {
    $username:
      ensure     => $user_present,
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
      name   => $groupname,
      gid    => $gid,
  }

  file {
    "/var/log/${service_name}":
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "/var/run/${service_name}":
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $groupname;
    "/etc/init.d/${service_name}":
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/gitpubsub/gitpubsub.${::asfosname}";
    'gitpubsub app dir':
      ensure => directory,
      path   => '/usr/local/etc/gitpubsub';
    '/usr/local/etc/gitpubsub/gitpubsub.lua':
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/gitpubsub/app/gitpubsub.lua';
    '/usr/local/etc/gitpubsub/config.lua':
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/gitpubsub/app/config.lua';
    '/usr/local/etc/gitpubsub/JSON.lua':
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/gitpubsub/app/JSON.lua';
    '/usr/local/etc/gitpubsub/gitpubsub.cfg':
      notify => Service[$service_name],
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/gitpubsub/config/gitpubsub.cfg';
  }

  service {
    $service_name:
      ensure    => $service_ensure,
      enable    => true,
      hasstatus => false,
  }
}
