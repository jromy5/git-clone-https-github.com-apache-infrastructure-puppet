# /etc/puppet/modules/wicket_pvm_asf/manifests/init.pp

class wicket_pvm_asf (

  $required_packages = ['tomcat8' , 'openjdk-8-jdk'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

