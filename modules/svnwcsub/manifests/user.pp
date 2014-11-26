
class svnwcsub::user inherits svnwcsub {

    user { "${username}":
        name       => "${username}",
        ensure     => present,
        home       => "/home/${username}",
        shell      => "${shell}",
        uid        => "${uid}",
        gid        => "${groupname}",
        groups     => "${groups}",
        managehome => true,
        require    => Group["${groupname}"],
    }

'
    group { "${groupname}":
        name   => "${groupname}",
        ensure => present,
        gid    => "${gid}",
    }

}
