# /etc/puppet/modules//default_pvm_asf/manifests/init.pp

class default_pvm_asf (

  $required_packages = ['joe' , 'ant' , 'unzip' , 'tomcat7'],
  $java = true,
  $java_version = '8', # 7, 8
  $java_ensure = 'latest', # present, latest, absent

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  if $java {
    class { 'oraclejava::install':
      ensure  => $java_ensure,
      version => $java_version,
    }
  }

}


