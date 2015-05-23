# /etc/puppet/modules//lucene1_pvm_asf/manifests/init.pp

class lucene1_pvm_asf (

  $jenkins_ssh
  $required_packages = ['joe' , 'ant'],

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
    home       => '/home/jenkins',
    managehome => true,
    uid        => '800',
  }

  file { '/etc/ssh/ssh_keys/jenkins.pub':
    content    => $jenkins_ssh,
    ensure     => 'present',
    owner      => 'root',
    group      => 'jenkins',
    require    => User['jenkins'],
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


