
class svnwcsub::config inherits svnwcsub {

    file { "/var/log/${service_name}":
        ensure => directory,
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
    }

    file { "/var/run/${service_name}":
        ensure => directory,
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
    }

    file { "/etc/init.d/${service_name}":
        mode   => 0755,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/svnwcsub/svnwcsub.${asfosname}",
    }

    file { "/home/${username}/${service_name}-hook":
        mode   => 0755,
        owner  => "${username}",
        group  => "${groupname}",
        source => 'puppet:///modules/svnwcsub/svnwcsub-hook',
    }

    file { "${conf_path}/${conf_file}":
        notify => Service["${service_name}"],
        mode   => 0644,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/svnwcsub/$conf_file",
    }

}
