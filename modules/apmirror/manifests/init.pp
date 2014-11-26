
class apmirror (
  $uid            = 508,
  $gid            = 508,
  $groupname      = 'apmirror',
  $groups         = [''],
  $service_ensure = 'running',
  $service_name   = 'svnwc',
  $shell          = '/bin/bash',
  $username       = 'apmirror',
){

   user { "${username}":
        name        => "${username}",
        ensure      => present,
        home        => "/home/${username}",
        shell       => "${shell}",
        uid         => "${uid}",
        gid         => "${groupname}",
        groups      => "${groups}",
        managehome  => true,
        require     => [ Group["${groupname}"], Group['svnwc'] ],
    }

    group { "${groupname}":
        name        => "${groupname}",
        ensure      => present,
        gid         => "${gid}",
    }

    exec { 'apmirror-co':
        command => 'svn co http://svn.apache.org/repos/asf/infrastructure/site-tools/trunk/mirrors/',
        path    => "/usr/bin/:/bin/",
        cwd     => "/home/${username}",
        user    => "${username}",
        group   => "${groupname}",
        creates => "/home/${username}/mirrors",
        require => [ Package['subversion'], User["${username}"] ],
    }

    cron { 'apmirror':
        command     => "/home/${username}/mirrors/runmirmon.sh",
        minute      => '19',
        user        => "${username}",
        require     => User["${username}"],
    }

    # Create symlinks to where the apmirror scripts think the binaries live

    file { '/usr/local/bin/wget':
        ensure  => 'link',
        target  => '/usr/bin/wget',
    }

}
