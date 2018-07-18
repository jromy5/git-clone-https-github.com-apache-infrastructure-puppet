# /etc/puppet/modules/wicket_pvm_asf/manifests/init.pp

class wicket_pvm_asf (

  $required_packages = ['tomcat8' , 'openjdk-8-jdk', 'docker-engine'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# download wicket docker images from ASF Bintray instance - one for each version for demo.
# for wicket-6
  -> exec {
    'download-wicket-docker-6':
      command => '/usr/bin/docker pull apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-6',
      timeout => 1200,
      require => Package['docker-engine'],
      notify  => Service['docker-wicket-demo-6'],
  }
# for wicket-7
  exec {
    'download-wicket-docker-7':
      command => '/usr/bin/docker pull apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-7',
      timeout => 1200,
      require => Package['docker-engine'],
      notify  => Service['docker-wicket-demo-7'],
  }
# for wicket-8
  exec {
    'download-wicket-docker-8':
      command => '/usr/bin/docker pull apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-8',
      timeout => 1200,
      require => Package['docker-engine'],
      notify  => Service['docker-wicket-demo-8'],
  }

  docker::run { 'wicket-demo-6':
    image            => 'apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-6',
    ports            => ['8086:8080'],
    restart_service  => true,
    privileged       => false,
    pull_on_start    => true,
    extra_parameters => [ '--restart=always' ],
  }

  docker::run { 'wicket-demo-7':
    image            => 'apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-7',
    ports            => ['8087:8080'],
    restart_service  => true,
    privileged       => false,
    pull_on_start    => true,
    extra_parameters => [ '--restart=always' ],
  }

  docker::run { 'wicket-demo-8':
    image            => 'apache-docker-wicket-docker.bintray.io/wicket-examples:LATEST-8',
    ports            => ['8088:8080'],
    restart_service  => true,
    privileged       => false,
    pull_on_start    => true,
    extra_parameters => [ '--restart=always' ],
  }

}

