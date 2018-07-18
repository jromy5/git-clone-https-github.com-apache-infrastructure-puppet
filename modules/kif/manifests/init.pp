#/etc/puppet/modules/kif/manifests/init.pp

class kif (
  $service_name   = 'kif',
  $shell          = '/bin/bash',
  $service_ensure = 'running',
  $username       = 'root',
  $group          = 'root',
  $httpd_connections = 400,
  $hipchat_token,
){
  require python

  package { 'python-yaml':
    ensure => present,
  }
  -> python::pip {
    'psutil' :
      ensure  => present,
      require => Package['python-yaml'];
    'requests' :
      ensure  => present;
  }
  -> file {
    '/usr/local/etc/kif':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/var/run/kif':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/etc/init.d/kif':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => "puppet:///modules/kif/kif.${::asfosname}";
    '/etc/default/kif':
      mode    => '0755',
      owner   => $username,
      group   => $group,
      content => '';
    '/lib/systemd/system/kif.service':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/kif/kif.service';
    '/usr/local/etc/kif/kif.py':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/kif/kif.py';
    '/usr/local/etc/kif/kif.yaml':
      mode    => '0755',
      owner   => $username,
      group   => $group,
      content => template('kif/kif.yaml.erb')
    }
    -> service { $service_name:
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => true,
        subscribe => [
          File['/usr/local/etc/kif/kif.py'],
          File['/usr/local/etc/kif/kif.yaml']
        ]
    }
}
