##/etc/puppet/modules/ubuntu1510-maven/manifests/init.pp

class ubuntu1510-maven (

  $required_packages             = []

) {

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }


  apt::source { 'wily':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'wily',
    repos    => 'main',
  }

  apt::source { 'wily-updates':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'wily-updates',
    repos    => 'main',
  }

  apt::pin { 'wily-maven':
    ensure   => present,
    priority => 1800,
    packages => 'maven',
    codename => 'wily',
    require  => Apt::Source['wily'],
    before   => Package['maven'],
  }

}
