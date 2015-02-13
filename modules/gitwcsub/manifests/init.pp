
class gitwcsub (
  $uid            = 9997,
  $gid            = 9997,
  $conf_path      = '/usr/local/etc/gitwcsub',
  $conf_file      = 'gitwcsub.cfg',
  $group_present  = 'present',
  $groupname      = 'svnwc',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'gitwcsub',
  $shell          = '/bin/bash',
  $source         = 'gitwcsub.cfg',
  $user_present   = 'present',
  $username       = 'svnwc',

){


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
        source => "puppet:///modules/gitwcsub/gitwcsub.${asfosname}",
    }
    
    file { 'app dir':
        ensure => directory,
        path => '/usr/local/etc/gitwcsub',
    }

    file { "/user/local/etc/gitwcsub/gitwcsub.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitwcsub/app/gitwcsub.lua',
    }
    
    file { "/user/local/etc/gitwcsub/config.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitwcsub/app/config.lua',
    }


    file { "/user/local/etc/gitwcsub/JSON.lua":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/gitwcsub/app/JSON.lua',
    }


    file { "/user/local/etc/gitwcsub/gitwcsub.cfg":
        mode   => 0644,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/gitwcsub/config/gitwcsub.cfg",
    }

    service { "${service_name}":
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => false,
        require   => Package['lua'],
    }

}
