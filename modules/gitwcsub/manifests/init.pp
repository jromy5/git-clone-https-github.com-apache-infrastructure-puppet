#/etc/puppet/modules/gitwcsub/manifests/init.pp

class gitwcsub (
  $uid            = 9994,
  $gid            = 9994,
  $conf_path      = '/usr/local/etc/gitwcsub',
  $conf_file      = 'gitwcsub.cfg',
  $group_present  = 'present',
  $groupname      = 'gitwc',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'gitwcsub',
  $shell          = '/bin/bash',
  $source         = 'gitwcsub.cfg',
  $user_present   = 'present',
  $username       = 'gitwc',

){


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
      source => "puppet:///modules/gitwcsub/gitwcsub.${::asfosname}";
    'app dir':
      ensure => directory,
      path   => '/usr/local/etc/gitwcsub';
    '/usr/local/etc/gitwcsub/gitwcsub.py':
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/gitwcsub/app/gitwcsub.py';
    '/usr/local/etc/gitwcsub/gitwcsub.cfg':
      notify => Service[$service_name],
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/gitwcsub/config/gitwcsub.cfg';
    }

    service { $service_name:
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => false,
    }

    logrotate::rule { 'gitwcsub':
      path         => '/var/log/gitwcsub/gitwcsub-current.log',
      rotate       => 7,
      rotate_every => 'day',
      compress     => true,
      create       => true,
      create_owner => 'svnwc',
      create_group => 'svnwc',
      create_mode  => '0644',
      dateext      => true,
      missingok    => true,
    }

}
