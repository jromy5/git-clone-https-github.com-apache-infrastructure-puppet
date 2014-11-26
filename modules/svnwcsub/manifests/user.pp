
class svnwcsub::user inherits svnwcsub {

    user { 'svnwc_user':
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
    group { 'svnwc_group':
        name   => "${groupname}",
        ensure => present,
        gid    => "${gid}",
    }

}
