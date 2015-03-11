
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

    package { 'lua':
      ensure => installed
    }
    package { 'lua-filesystem':
      ensure => installed
    }
    package { 'lua-socket':
      ensure => installed
    }
  
    user { "${username}":
         name       => "${username}",
         ensure     => "${user_present}",
         home       => "/home/${username}",
         shell      => "${shell}",
         uid        => "${uid}",
         gid        => "${groupname}",
         groups     => $groups,
         managehome => true,
         require    => Group["${groupname}"],
     }

    group { "${groupname}":
        name   => "${groupname}",
        ensure => "${group_present}",
        gid    => "${gid}",
    }

    file { "/var/log/${service_name}":
        ensure => directory,
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
    }

    file { "/var/run/${service_name}":
        ensure => directory,
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
    }

    file { "/etc/init.d/${service_name}":
        mode   => 0755,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/gitpubsub/gitpubsub.${asfosname}",
    }
    
    file { 'app dir':
        ensure => directory,
        path => '/usr/local/etc/gitpubsub',
    }

    file { "/usr/local/etc/gitpubsub/gitpubsub.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitpubsub/app/gitpubsub.lua',
    }
    
    file { "/usr/local/etc/gitpubsub/config.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitpubsub/app/config.lua',
    }
    
    file { "/usr/local/etc/gitpubsub/JSON.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitpubsub/app/JSON.lua',
    }


    file { "/usr/local/etc/gitpubsub/gitpubsub.cfg":
        notify => Service["${service_name}"],
        mode   => 0644,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitpubsub/config/gitpubsub.cfg',
    }

    service { "${service_name}":
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => false,
    }

}
