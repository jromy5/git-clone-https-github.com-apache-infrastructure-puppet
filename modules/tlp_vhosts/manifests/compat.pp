
class tlp_vhosts::compat inherits tlp_vhosts {

    # Create wget and rsync symlink to the fbsd locations
    # to appease the hardcoded binary locations in the
    # scripts
    file { '/usr/local/bin/rsync':
        ensure  => 'link',
        target  => '/usr/bin/rsync',
    }

    file { '/usr/local/bin/svn':
        ensure  => 'link',
        target  => '/usr/bin/svn',
    }

    file { '/www':
        ensure  => 'link',
        target  => '/var/www',
    }
    
    file { '/x1':
        ensure  => 'link',
        target  => '/var',
    }

    file { '/usr/local/bin/python2.7':
        ensure  => 'link',
        target  => '/usr/bin/python2.7',
    }

    $apache_org_dirs = ['/var/www', '/var/www/www.apache.org']

    file { $apache_org_dirs:
        ensure  => 'directory',
        owner   => 'svnwc',
        group   => 'apmirror',
        mode    => '2775',
    }

    file { '/var/www/www.apache.org/dist':
        ensure  => 'directory',
        owner   => 'apmirror',
        group   => 'apmirror',
        mode    => '0775',
    }

    file { '.htaccess':
        ensure  => 'present',
        owner   => 'svnwc',
        group   => 'apmirror',
        path    => '/var/www/www.apache.org/dist/.htaccess',
        source  => 'puppet:///modules/tlp_vhosts/dist/.htaccess',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { '.message':
        ensure  => 'present',
        owner   => 'svnwc',
        group   => 'apmirror',
        path    => '/var/www/www.apache.org/dist/.message',
        source  => 'puppet:///modules/tlp_vhosts/dist/.message',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'favicon.ico':
        ensure  => 'present',
        owner   => 'svnwc',
        group   => 'apmirror',
        path    => '/var/www/www.apache.org/dist/favicon.ico',
        source  => 'puppet:///modules/tlp_vhosts/dist/favicon.ico',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'HEADER.html':
        ensure  => 'present',
        owner   => 'svnwc',
        group   => 'apmirror',
        path    => '/var/www/www.apache.org/dist/HEADER.html',
        source  => 'puppet:///modules/tlp_vhosts/dist/HEADER.html',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'README.html':
        ensure  => 'present',
        owner   => 'svnwc',
        group   => 'apmirror',
        path    => '/var/www/www.apache.org/dist/README.html',
        source  => 'puppet:///modules/tlp_vhosts/dist/README.html',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { '/var/www/www.apache.org/dist/zzz':
        ensure  => 'directory',
        owner   => 'svnwc',
        group   => 'apmirror',
        source  => 'puppet:///modules/tlp_vhosts/zzz',
        recurse => true,
        require => File['/var/www/www.apache.org/dist'],
    }

    $packages = ['python-geoip', 'swish-e', 'python-flup']

    package { $packages:
        ensure  => 'latest',
    }

}
