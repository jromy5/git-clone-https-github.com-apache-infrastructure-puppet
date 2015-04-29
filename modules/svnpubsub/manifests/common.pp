#/etc/puppet/modules/svnpubsub/manifes/common.pp

class svnpubsub::common {

    exec { 'pubsub-co':
        command => 'svn co http://svn.eu.apache.org/repos/asf/subversion/trunk/tools/server-side/svnpubsub',
        path    => '/usr/bin/:/bin/',
        cwd     => '/opt',
        creates => '/opt/svnpubsub',
        require => Package['subversion'],
    }
}
