
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

    $apache_org_dirs = ['/var/www', '/var/www/www.apache.org', '/var/www/www.apache.org/dist', '/var/www/www.apache.org/dist/zzz']

    file { $apache_org_dirs:
        ensure  => 'directory',
        owner   => 'svnwc',
        group   => 'apmirror',
        mode    => '2775',
    }

    file { '.htaccess':
        ensure  => present,
        path    => '/var/www/www.apache.org/dist/.htaccess',
        mode    => 0644,
        owner   => 'svnwc',
        group   => 'svnwc',
        source  => 'puppet:///modules/tlp_vhosts/.htaccess',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { '.message':
        ensure  => present,
        path    => '/var/www/www.apache.org/dist/.message',
        mode    => 0644,
        owner   => 'svnwc',
        group   => 'svnwc',
        source  => 'puppet:///modules/tlp_vhosts/.message',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'README.html':
        ensure  => present,
        path    => '/var/www/www.apache.org/dist/README.html',
        mode    => 0644,
        owner   => 'svnwc',
        group   => 'svnwc',
        source  => 'puppet:///modules/tlp_vhosts/README.html',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'HEADER.html':
        ensure  => present,
        path    => '/var/www/www.apache.org/dist/HEADER.html',
        mode    => 0644,
        owner   => 'svnwc',
        group   => 'svnwc',
        source  => 'puppet:///modules/tlp_vhosts/HEADER.html',
        require => File['/var/www/www.apache.org/dist'],
    }

    file { 'favicon.ico':
        ensure  => present,
        path    => '/var/www/www.apache.org/dist/favicon.ico',
        mode    => 0644,
        owner   => 'svnwc',
        group   => 'svnwc',
        source  => 'puppet:///modules/tlp_vhosts/favicon.ico',
        require => File['/var/www/www.apache.org/dist'],
    }

    $packages = ['python-geoip', 'swish-e', 'python-flup']

    package { $packages:
        ensure  => 'latest',
    }

}
