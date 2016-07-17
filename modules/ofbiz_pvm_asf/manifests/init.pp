# /etc/puppet/modules/ofbiz_pvm_asf/manifests/init.pp

class ofbiz_pvm_asf (

  $required_packages = [''],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  # manifest for ofbiz project vm

  user { 'ofbizDemo':
    ensure     => present,
    name       => 'ofbizDemo',
    comment    => 'ofbiz role account',
    home       => '/home/ofbizDemo',
    managehome => true,
    system     => true,
  }
}

