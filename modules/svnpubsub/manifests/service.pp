
class svnpubsub::service inherits svnpubsub {

    service { "svnpubsub":
        ensure => running,
        enable => true,
        hasstatus => false,
    }
}
