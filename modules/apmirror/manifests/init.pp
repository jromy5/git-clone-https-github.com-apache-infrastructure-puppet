
class apmirror (
    $uid            = 508,
    $gid            = 508,
){

   user { 'apmirror':
        name        => 'apmirror',
        ensure      => present,
        home        => '/home/apmirror',
        shell       => '/bin/bash',
        uid         => $uid,
        gid         => 'apmirror',
        groups      => ['svnwc'],
        managehome  => true,
        require     => [ Group['apmirror'], Group['svnwc'] ],
    }

    group { 'apmirror':
        name        => 'apmirror',
        ensure      => present,
        gid         => $gid,
    }

    exec { 'apmirror-co':
        command     => 'svn co http://svn.apache.org/repos/asf/infrastructure/site-tools/trunk/mirrors/',
        path        => "/usr/bin/:/bin/",
        cwd         => '/home/apmirror',
        user        => 'apmirror',
        group       => 'apmirror',
        require     => [ Package['subversion'], User['apmirror'] ],
    }

    cron { 'apmirror':
        command     => '/home/apmirror/mirrors/runmirmon.sh',
        minute      => '19',
        user        => 'apmirror',
        require     => User['apmirror'],
    }

    # Create symlinks to where the apmirror scripts think the binaries live

    file { '/usr/local/bin/wget':
        ensure  => 'link',
        target  => '/usr/bin/wget',
    }

}
