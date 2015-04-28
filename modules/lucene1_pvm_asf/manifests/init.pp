class lucene1_pvm_asf {

  # manifest for lucene project vm

  user { 'jenkins':
    ensure     => present,
    name       => 'jenkins',
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
    ensure   => present,
    priority => 1800,
    packages => 'subversion',
    codename => 'precise',
    require  => Apt::Source['precise'],
    before   => Package['subversion'],
  }
  
  apt::pin { 'precise-libsvn1':
    ensure   => present,
    priority => 1800,
    packages => 'libsvn1',
    codename => 'precise',
    require  => Apt::Source['precise'],
  }

}


