# /etc/puppet/modules/ofbiz_pvm_asf/manifests/init.pp

class ofbiz_pvm_asf (

  $demouser = 'ofbizDemo',
  $required_packages = [],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# ensure user exists
  user { $demouser:
    ensure     => present,
    name       => $demouser,
    comment    => 'ofbiz role account',
    home       => "/home/${demouser}",
    managehome => true,
    system     => true,
  }

# ensure bigfiles parent dir exists
  file { '/var/www/ofbiz':
    ensure  => directory,
    owner   => $demouser,
    group   => 'www-data',
    require => [User[$demouser],Class['apache']];
  }
}

