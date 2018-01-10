#/etc/puppet/modules/selfserve/manifests/init.pp

# selfserve class for id.a.o
class selfserve (

  # Below contained in eyaml

  $pw_reset_magic = '',
  $session_magic  = '',
  $system_dn      = '',
  $system_pw      = '',
  $system_read_dn = '',
  $system_read_pw = '',

  $required_packages = ['python-ldap' , 'python-gnupg'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  $install_dir = '/var/www/selfserve'

file {
    $install_dir:
      ensure  => directory,
      recurse => true,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/selfserve/selfserve',
      require => Package['apache2'];
    "${install_dir}/state":
      ensure => directory,
      owner  => 'www-data',
      group  => 'lpadmin',
      mode   => '0740';
    "${install_dir}/config":
      ensure => directory,
      mode   => '0755';
    "${install_dir}/login-as.sh":
      content => template('selfserve/login-as.sh.erb'),
      mode    => '0755';
    "${install_dir}/lib/ss2config.py":
      content => template('selfserve/ss2config.py.erb'),
      mode    => '0644';
    "${install_dir}/config/ssconfigprivate.py":
      content => template('selfserve/ssconfigprivate.py.erb'),
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640';
  }
}
