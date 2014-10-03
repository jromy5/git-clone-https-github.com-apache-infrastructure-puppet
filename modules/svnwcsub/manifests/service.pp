
class svnwcsub::service inherits svnwcsub {

    service { 'svnwcsub':
        ensure => running,
        enable => true,
        hsstatus => false,
    }
}
