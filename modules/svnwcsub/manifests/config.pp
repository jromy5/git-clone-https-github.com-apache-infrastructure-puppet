
class svnwcsub::config inherits svnwcsub {

    file { '/var/log/svnwcsub':
        ensure => directory,
        mode   => 0755,
        owner  => 'svnwc',
        group  => 'svnwc',
    }

    file { '/var/run/svnwcsub':
        ensure => directory,
        mode   => 0755,
        owner  => 'svnwc',
        group  => 'svnwc',
    }

    file { '/etc/init.d/svnwcsub':
        mode   => 0755,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/svnwcsub/svnwcsub.debian',
    }

    file { '/home/svnwc/svnwcsub-hook':
        mode   => 0755,
        owner  => 'svnwc',
        group  => 'svnwc',
        source => 'puppet:///modules/svnwcsub/svnwcsub-hook',
    }

    file { '/etc/svnwcsub.conf':
        notify => Service["svnwcsub"],
        mode   => 0644,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/svnwcsub/$conf_file",
    }

}
