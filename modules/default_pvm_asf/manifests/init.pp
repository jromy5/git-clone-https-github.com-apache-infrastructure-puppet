# /etc/puppet/modules//default_pvm_asf/manifests/init.pp

class default_pvm_asf (

  $required_packages = ['joe' , 'ant' , 'unzip'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  include java8

}


