#/etc/puppet/modules/loggy/manifests/init.pp

class loggy (
  $service_name   = 'loggy',
  $shell          = '/bin/bash',
  $service_ensure = 'running',
  $username       = 'root',
  $group          = 'root',
  $packages       = ['elasticsearch', 'python-inotify==0.6-test']

){
  package { $packages:
    ensure   => installed,
    provider => 'pip',
    }

  file {
    '/usr/local/etc/loggy':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/var/run/loggy':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/etc/init.d/loggy':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => "puppet:///modules/loggy/loggy.${::asfosname}";
    'loggy app dir':
      ensure => directory,
      path   => '/usr/local/etc/loggy';
    '/usr/local/etc/loggy/loggy.py':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/loggy/loggy.py';
    }

    service { $service_name:
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => false,
    }
}
