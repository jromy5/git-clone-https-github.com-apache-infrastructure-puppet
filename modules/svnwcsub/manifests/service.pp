
class svnwcsub::service inherits svnwcsub {
    include svnpubsub::common

    service { 'svnwcsub':
        ensure => stopped,
        enable => true,
        hasstatus => false,
        require => Class['svnpubsub::common'],
    }
}
