# /etc/puppet/modules/netbeans_pvm_asf/manifests/init.pp

class netbeans_pvm_asf (

  $required_packages = ['subversion' , 'php7.0' , 'php7.0-cli' , 'php7.0-mysql'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

