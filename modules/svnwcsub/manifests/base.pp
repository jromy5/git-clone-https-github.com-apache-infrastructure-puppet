
class svnwcsub::base inherits svnwcsub {

    user { 'svnwc':
        name       => 'svnwc',
        ensure     => present,
        home       => '/home/svnwc',
        shell      => '/bin/bash',
        uid        => $uid,
        gid        => 'svnwc',
        groups     => ['apmirror'],
        managehome => true,
        require    => Group['svnwc'],
    }


    group { 'svnwc':
        name   => 'svnwc',
        ensure => present,
        gid    => $gid,
    }

#    exec { 'apache_perms':
#        path => ['/bin/'],
#        command => 'chown svnwc:www-data /var/www ; chmod 2755 /var/www',
#        require => User['svnwc'],
#    }
}
