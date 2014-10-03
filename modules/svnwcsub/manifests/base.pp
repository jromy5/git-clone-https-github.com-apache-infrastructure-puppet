
class svnwcsub::base inherits svnwcsub {

    user { 'svnwc':
        name => 'svnwc',
        ensure => present,
        home => '/home/svnwc',
        shell => '/bin/bash',
        uid => '9997',
        gid => 'svnwc',
        managehome => true,
        require => Group['svnwc'],
    }

    group { 'svnwc':
        name => 'svnwc',
        ensure => present,
        gid => '9997',
    }
}
