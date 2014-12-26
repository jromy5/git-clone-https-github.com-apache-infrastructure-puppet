
class apmirror (
  $uid            = 508,
  $gid            = 508,
  $groupname      = 'apmirror',
  $groups         = [],
  $service_ensure = 'running',
  $service_name   = 'svnwc',
  $shell          = '/bin/bash',
  $username       = 'apmirror',
){

   require svnwcsub

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

    # create mirmon file to allow mirror priming to work

    file { 'mirmon.state':
        path    => "/home/${username}/mirrors/mirmon/mirmon.state",
        group   => "${groupname}",
        owner   => "${username}",
        ensure  => 'file',
        require => [ Exec['apmirror-co'], User["${username}"] ],
    }

    exec { 'create mirmon.mlist':
        command => 'perl mk_mlist mirrors.list mirmon/mirmon.mlist',
        path    => '/usr/bin:/bin',
        cwd     => "/home/${username}/mirrors",
        user    => "${username}",
        group   => "${groupname}",
        creates => "/home/${username}/mirrors/mirmon/mirmon.mlist",
        require => Exec['apmirror-co'],
    }

    exec { 'apache.org co':
        command => 'svn co https://svn-master.apache.org/repos/infra/websites/production/www/ www.apache.org',
        path    => '/usr/bin:/bin/',
        cwd     => '/var/www/',
        user    => 'svnwc',
        group   => "${groupname}",
        creates => '/var/www/www.apache.org/content',
        require => [ Package['subversion'], User['svnwc'], Group["${groupname}"] ],
    }

    file { 'mirrors':
        path    => '/var/www/www.apache.org/content/mirrors',
        mode    => '2775',
        owner   => 'svnwc',
        group   => "${groupname}",
        require => Exec['apache.org co'],
    }

    exec { 'mirmon list prime':
        command => 'perl mirmon -get "all"',
        path    => "/usr/local/bin:/usr/bin:/bin:/home/${username}/mirrors/mirmon",
        cwd     => "/home/${username}/mirrors/mirmon/",
        user    => "${username}",
        group   => "${groupname}",
        creates => "/home/${username}/mirrors/mirmon/url-mods.new",
        require => [ File['mirmon.state'], Exec['create mirmon.mlist'], Exec['apache.org co'], File['mirrors'] ],
    }

}
