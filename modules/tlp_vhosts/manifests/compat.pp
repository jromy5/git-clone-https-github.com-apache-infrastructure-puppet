#/etc/puppet/modules/tlp_vhosts/manifests.compat.pp

class tlp_vhosts::compat {

  # Create wget and rsync symlink to the fbsd locations
  # to appease the hardcoded binary locations in the
  # scripts
  file { '/usr/local/bin/rsync':
    ensure => 'link',
    target => '/usr/bin/rsync',
  }

  file { '/usr/local/bin/svn':
    ensure => 'link',
    target => '/usr/bin/svn',
  }

  file { '/www':
    ensure => 'link',
    target => '/var/www',
  }

  file { '/x1':
    ensure => directory,
  }

  file { '/dist':
    ensure  => 'link',
    target  => '/var/www/www.apache.org/dist',
    require => File['/var/www/www.apache.org/dist'],
  }


  file { '/usr/local/bin/python2.7':
    ensure => 'link',
    target => '/usr/bin/python2.7',
  }

  $apache_org_dirs = ['/var/www',
                      '/var/www/www.apache.org',
                      '/var/www/www.apache.org/dist']

  file { $apache_org_dirs:
    ensure => 'directory',
    owner  => $svnwcsub::username,
    group  => $svnwcsub::groupname,
    mode   => '2775',
  }

  $packages = ['python-geoip', 'swish-e', 'python-flup']

  package { $packages:
    ensure => 'latest',
  }

}
