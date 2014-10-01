
class svnpubsub (
) {

    package { 'subversion':
        name => 'subversion',
        ensure => latest,
    }

    exec { 'pubsub-co':
        command => 'svn co --force https://svn.apache.org/viewvc/subversion/trunk/tools/server-side/svnpubsub',
        path => "/usr/bin/:/bin/",
        cwd => '/opt',
        require => Package['subversion'],
    }

    file { "/var/log/svnpubsub":
        ensure => directory,
    }
    
    file { "/etc/init.d/svnpubsub":
        mode => '0755',
        owner => 'root',
        group => 'root',
        source => '/opt/svnpubsub/rc.d/svnpubsub.debian',
        require => Exec['pubsub-co'],
        notify => Service[svnpubsub],
    }

    service { "svnpubsub":
        ensure => running,
        enable => true,
        hasstatus => false,
        require => File['/etc/init.d/svnpubsub', '/var/log/svnpubsub'],
    }

}
