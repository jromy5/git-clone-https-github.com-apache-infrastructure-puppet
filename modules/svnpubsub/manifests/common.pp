
class svnpubsub::common {

    package { 'subversion':
        ensure => latest,
    }

    exec { 'pubsub-co':
        command => 'svn co http://svn.apache.org/repos/asf/subversion/trunk/tools/server-side/svnpubsub',
        path => "/usr/bin/:/bin/",
        cwd => '/opt',
        require => Package['subversion'],
    }
}
