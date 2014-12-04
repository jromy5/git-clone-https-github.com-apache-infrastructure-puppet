class svnpubsub (
  
  $packages       = ['python-twisted']
  $service_ensure = 'running',
  $service_name   = 'svnpubsub',
) {

    include svnpubsub::common

    package { $packages:
      ensure => latest,
    }

    file { "/var/log/${service_name}":
        ensure => directory,
    }

    file { "/var/run/${service_name}":
        ensure  => directory,
        mode    => 0755,
        owner   => 'daemon',
        group   => 'daemon',
    }

    file { "/etc/init.d/${service_name}":
        mode    => 0755,
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/svnpubsub/svnpubsub.${asfosname}",
    }

    service { "${service_name}":
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => false,
        require   => Class['svnpubsub::common'],
    }

}
