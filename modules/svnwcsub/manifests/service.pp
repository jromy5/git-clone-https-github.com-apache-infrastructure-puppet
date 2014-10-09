
class svnwcsub::service inherits svnwcsub {
    require svnpubsub::common

    service { 'svnwcsub':
        ensure => $service_ensure,
        enable => true,
        hasstatus => false,
        require => Class['svnpubsub::common'],
    }
}
