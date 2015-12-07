##/etc/puppet/modules/security_pvm_asf/manifests/init.pp

class security_pvm_asf (

  $required_packages = ['maven3', 'openjdk-8-jdk']

) {

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  apt::ppa { 'ppa:openjdk-r/ppa':
    ensure => present,
    before => Package['openjdk-8-jdk'],
  }

  apt::ppa { 'ppa:andrei-pozolotin/maven3':
    ensure => present,
    before => Package['maven3'],
  }

}
