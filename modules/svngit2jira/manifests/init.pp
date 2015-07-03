#/etc/puppet/modules/svngit2jira/manifest/init.pp

class svngit2jira (
  $uid            = 9992,
  $gid            = 9992,
  $conf_path      = '/usr/local/etc/svngit2jira',
  $conf_file      = 'svngit2jira.cfg',
  $group_present  = 'present',
  $groupname      = 'svngit2jira',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'svngit2jira',
  $shell          = '/bin/bash',
  $source         = 'svngit2jira.cfg',
  $user_present   = 'present',
  $username       = 'svngit2jira',

){

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
      source => "puppet:///modules/svngit2jira/svngit2jira.${::asfosname}",
    }

    file { 'svngit2jira app dir':
      ensure => directory,
      path   => '/usr/local/etc/svngit2jira',
    }

    file { '/usr/local/etc/svngit2jira/svngit2jira.py':
      mode   => '0755',
      owner  => $username,
      group  => $groupname,
      source => 'puppet:///modules/svngit2jira/app/svngit2jira.py',
    }


    file { '/usr/local/etc/svngit2jira/svngit2jira.cfg':
      notify => Service[$service_name],
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/svngit2jira/config/svngit2jira.cfg',
    }

    service { $service_name:
      ensure    => $service_ensure,
      enable    => true,
      hasstatus => false,
    }

}
