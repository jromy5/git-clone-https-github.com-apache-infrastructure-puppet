
class svnpubsub::config inherits svnpubsub {
    include svnpubsub::common

    file { "/var/log/svnpubsub":
        ensure => directory,
    }

    file { "/etc/init.d/svnpubsub":
        mode => '0755',
        owner => 'root',
        group => 'root',
        source => '/opt/svnpubsub/rc.d/svnpubsub.debian',
        require => Class['svnpubsub::common'],
    }
}
