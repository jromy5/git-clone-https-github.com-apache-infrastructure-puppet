# /etc/puppet/modules//lucene1_pvm_asf/manifests/init.pp

class lucene1_pvm_asf (

  $jenkins_ssh,
  $required_packages = ['joe' , 'ant' , 'unzip'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # manifest for lucene project vm

  user { 'jenkins':
    ensure     => present,
    name       => 'jenkins',
    comment    => 'lucene project VM jenkins slave',
    home       => '/x1/jenkins',
    managehome => true,
    uid        => '800',
  }

  file { '/home/jenkins':
    ensure  => 'link',
    target  => '/x1/jenkins',
    require => User['jenkins'],
  }

  file { '/etc/ssh/ssh_keys/jenkins.pub':
    ensure  => 'present',
    content => $jenkins_ssh,
    owner   => 'root',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  apt::source { 'precise':
    ensure   => absent,
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'precise',
    repos    => 'main',
  }

  apt::source { 'precise-updates':
    ensure   => absent,
    location => 'http://us.archive.ubuntu.com/ubuntu/',
    release  => 'precise-updates',
    repos    => 'main',
  }

  apt::pin { 'precise-subversion':
    ensure   => absent,
    priority => 1800,
    packages => 'subversion',
    codename => 'precise',
    require  => Apt::Source['precise'],
    before   => Package['subversion'],
  }

  apt::pin { 'precise-libsvn1':
    ensure   => absent,
    priority => 1800,
    packages => 'libsvn1',
    codename => 'precise',
    require  => Apt::Source['precise'],
  }

}


