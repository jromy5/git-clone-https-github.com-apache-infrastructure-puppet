# /etc/puppet/modules/wicket_pvm_asf/manifests/init.pp

class wicket_pvm_asf (

  $required_packages = ['tomcat8' , 'openjdk-8-jdk', 'docker-engine'],

  # override below in yaml
  $wicket_examples_version = '',

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }->

# download wicket docker image from ASF Bintray instance
  exec {
    'download-wicket-docker':
      command => "/usr/bin/docker pull apache-docker-wicket-docker.bintray.io/wicket-examples:${wicket_examples_version}",
      timeout => 1200,
      require => Package['docker-engine'],
  }

}
