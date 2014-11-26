
class svnpubsub::common {

    exec { 'pubsub-co':
        command => 'svn co http://svn.apache.org/repos/asf/subversion/trunk/tools/server-side/svnpubsub',
        path    => "/usr/bin/:/bin/",
        cwd     => '/opt',
        creates => '/opt/svnpubsub',
        require => Package['subversion'],
    }
}
