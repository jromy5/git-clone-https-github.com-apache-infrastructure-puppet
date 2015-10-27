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

  user { 'forrest':
    ensure     => present,
    name       => 'forrest',
    comment    => 'forrest role account',
    home       => '/home/forrest',
    managehome => true,
  }
}
