class lucene1-pvm_asf {

  # manifest for lucene project vm

  user { 'jenkins':
    name       => 'jenkins',
    ensure     => present,
    comment    => 'lucene project VM jenkins slave',
    home       => '/home/jenkins',
    managehome => true,
    uid        => '800',
  }

  apt::source { 'precise':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'precise',
    repos    => 'main',
  }

  apt::source { 'precise-updates':
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'precise-updates',
    repos    => 'main',
  }

  apt::pin { 'precise-subversion': 
    priority => 1800,
    ensure   => present,
    packages => 'subversion',
    codename => 'precise',
    require  => Apt::Source['precise'],
    before   => Package['subversion'],
  }
  
  apt::pin { 'precise-libsvn1': 
    priority => 1800,
    ensure   => present,
    packages => 'libsvn1',
    codename => 'precise',
    require  => Apt::Source['precise'],
  }

}


