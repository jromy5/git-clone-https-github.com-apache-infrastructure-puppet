
class tlp_vhosts::base inherits tlp_vhosts {

    user { 'apmirror':
        name => 'apmirror',
        ensure => present,
        home => '/home/apmirror',
        shell => '/bin/bash',
        uid => $uid,
        gid => 'apmirror',
        gid => $::svnwcsub::gid,
        managehome => true,
        require => Group['apmirror'],
    }

    group { 'apmirror':
        name => 'apmirror',
        ensure => present,
        gid => $gid,
    }

    exec { 'apmirror-co':
        command => 'svn co http://svn.apache.org/repos/asf/infrastructure/site-tools/trunk/mirrors/',
        path => "/usr/bin/:/bin/",
        cwd => '/home/apmirror',
        require => [ Package['subversion'], User['apmirror'] Class['svnwcsub::base'] ],
    }
}
