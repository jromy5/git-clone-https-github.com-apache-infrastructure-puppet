
class svnpubsub::config inherits svnpubsub {
    include svnpubsub::common

    file { "/var/log/svnpubsub":
        ensure => directory,
    }

    file { '/var/run/svnpubsub':
        ensure => directory,
        mode => 0755,
        owner => 'daemon',
        group => 'daemon',
    }

    file { "/etc/init.d/svnpubsub":
        mode => 0755,
        owner => 'root',
        group => 'root',
        source => 'puppet:///modules/svnpubsub/svnpubsub.debian',
    }
}
