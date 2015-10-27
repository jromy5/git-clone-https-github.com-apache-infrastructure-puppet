# /etc/puppet/modules//forrest_pvm_asf/manifests/init.pp

class forrest_pvm_asf (

  $required_packages = ['bsd-mailx'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # manifest for forrest project vm

  user { 'forrest_role':
    ensure     => present,
    name       => 'forrest_role',
    comment    => 'forrest role account',
    home       => '/home/forrest_role',
    managehome => true,
    system     => true,
  }
}
