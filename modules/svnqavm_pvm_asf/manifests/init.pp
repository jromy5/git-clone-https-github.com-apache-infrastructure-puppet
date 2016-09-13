# /etc/puppet/modules/svnqavm_pvm_asf/manifests/init.pp

class svnqavm_pvm_asf (

  $required_packages = [],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # manifest for svnqavm project vm

  user { 'svnsvn':
    ensure     => present,
    name       => 'svn_role',
    comment    => 'svn role account',
    home       => '/home/svnsvn',
    managehome => true,
    system     => true,
  }

  user { 'wayita':
    ensure     => present,
    name       => 'wayita_role',
    comment    => 'wayita role account',
    home       => '/home/wayita',
    managehome => true,
    system     => true,
  }

}
