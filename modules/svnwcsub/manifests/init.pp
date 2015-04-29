# /etc/puppet/modules/svnwcsub/manifests/init.pp

class svnwcsub (
  $uid            = 9997,
  $gid            = 9997,
  $conf_path      = '/etc',
  $conf_file      = 'svnwcsub.conf',
  $group_present  = 'present',
  $groupname      = 'svnwc',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'svnwcsub',
  $shell          = '/bin/bash',
  $source         = 'svnwcsub.conf',
  $user_present   = 'present',
  $username       = 'svnwc',

){

  include svnpubsub::common

  user { $username:
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

  group { $groupname:
    ensure => $group_present,
    name   => $groupname,
    gid    => $gid,
  }

  file { 'svnwc profile':
    ensure  => 'present',
    path    => "/home/${username}/.profile",
    mode    => '0644',
    owner   => $username,
    group   => $groupname,
    source  => 'puppet:///modules/svnwcsub/home/profile',
    require => User[$username],
  }


  file { "/var/log/${service_name}":
    ensure => directory,
    mode   => '0755',
    owner  => $username,
    group  => $groupname,
  }

  file { "/var/run/${service_name}":
    ensure => directory,
    mode   => '0755',
    owner  => $username,
    group  => $groupname,
  }

  file { "/etc/init.d/${service_name}":
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => "puppet:///modules/svnwcsub/svnwcsub.${::asfosname}",
  }

  file { "/home/${username}/${service_name}-hook":
    mode   => '0755',
    owner  => $username,
    group  => $groupname,
    source => 'puppet:///modules/svnwcsub/svnwcsub-hook',
  }

  file { "${conf_path}/${conf_file}":
    notify => Service[$service_name],
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    source => "puppet:///modules/svnwcsub/${source}",
  }

  service { $service_name:
    ensure    => $service_ensure,
    enable    => true,
    hasstatus => false,
    require   => Class['svnpubsub::common'],
  }

}
