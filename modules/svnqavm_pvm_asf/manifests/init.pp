# /etc/puppet/modules/svnqavm_pvm_asf/manifests/init.pp

class svnqavm_pvm_asf (

  $required_packages = ['libapr1-dev' , 'libaprutil1-dev'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # manifest for svnqavm project vm

  user { 'svnsvn':
    ensure     => present,
    name       => 'svnsvn',
    comment    => 'svn role account',
    home       => '/home/svnsvn',
    managehome => true,
    system     => true,
  }

  user { 'wayita':
    ensure     => present,
    name       => 'wayita',
    comment    => 'wayita role account',
    home       => '/home/wayita',
    managehome => true,
    system     => true,
  }

}
