
class tlp_vhosts::compat inherits tlp_vhosts {

    # Create wget and rsync symlink to the fbsd locations
    # to appease the hardcoded binary locations in the
    # scripts
    file { '/usr/local/bin/rsync':
        ensure => 'link',
        target => '/usr/bin/rsync',
    }

    file { '/usr/local/bin/wget':
        ensure => 'link',
        target => '/usr/bin/wget',
    }

    file { '/www':
        ensure => 'link',
        target => '/var/www',
    }
    
    file { '/x1':
        ensure => 'link',
        target => '/var',
    }

    file { '/usr/local/bin/python2.7':
        ensure => 'link',
        target => '/usr/bin/python2.7',
    }

    $apache_org_dirs = ['/var/www', '/var/www/www.apache.org', '/var/www/www.apache.org/dist', '/var/www/www.apache.org/dist/zzz']

    file { $apache_org_dirs:
        ensure => 'directory',
        owner => 'svnwc',
        group => 'apmirror',
        mode => '2775',
    }


    $packages = ['python-geoip', 'swish-e']
    package { $packages:
        ensure => 'latest',
    }

}
