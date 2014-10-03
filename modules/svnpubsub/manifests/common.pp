
class svnpubsub::common {

    package { 'subversion':
        ensure => latest,
    }

    exec { 'pubsub-co':
        command => 'svn co --force https://svn.apache.org/viewvc/subversion/trunk/tools/server-side/svnpubsub',
        path => "/usr/bin/:/bin/",
        cwd => '/opt',
        require => Package['subversion'],
    }
}
