
class svnwcsub::base inherits svnwcsub {
    include apache

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

    exec { 'apache_perms':
        path => ['/bin/'],
        command => 'chown svnwc:www-data /var/www ; chmod 2755 /var/www',
        require => [ User['svnwc'], Class['apache'] ],
    }
}
