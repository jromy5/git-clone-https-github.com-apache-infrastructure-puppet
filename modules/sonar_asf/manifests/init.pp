#/etc/puppet/modules/sonar_asf/manifests/init.pp

class sonar_asf (

  $required_packages             = ['tomcat8'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# Sonar specific TBD
}
