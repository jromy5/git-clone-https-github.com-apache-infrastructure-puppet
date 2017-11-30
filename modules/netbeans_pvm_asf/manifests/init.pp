# /etc/puppet/modules/netbeans_pvm_asf/manifests/init.pp

class netbeans_pvm_asf (

  # override below in eyaml.

  $nb_db_url         = '',
  $nb_db_user        = '',
  $nb_db_pw          = '',
  $nb_db_name        = '',
  $nb_db_hostname    = '',

  $required_packages = ['php7.0' , 'php7.0-cli' , 'php7.0-mysql'],

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# files

  file {
    '/usr/local/db_config.php':
      ensure  => 'present',
      mode    => '0755',
      content => template('netbeans_pvm_asf/db_config.php.erb');

    '/var/www/html/':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0755',
      require => Package['apache2'];
  }
}
