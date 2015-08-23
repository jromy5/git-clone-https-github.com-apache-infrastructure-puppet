#/etc/puppet/modules/loggy/manifests/init.pp

class loggy (
  $service_name   = 'loggy',
  $shell          = '/bin/bash',
  $service_ensure = 'running',
  $username       = 'root',
  $group          = 'root',
){
  require python

  python::pip {
    'elasticsearch' :
      ensure        => '1.6.0';
    'python-inotify==0.6-test' :
      ensure        => present
  } ->

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
    '/usr/local/etc/loggy/loggy.py':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/loggy/loggy.py';
    '/usr/local/etc/loggy/loggy.cfg':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/loggy/loggy.cfg';
    } ->

    service { $service_name:
        ensure    => $service_ensure,
        enable    => true,
        hasstatus => true,
        subscribe => [
          File['/usr/local/etc/loggy/loggy.py'],
          File['/usr/local/etc/loggy/loggy.cfg']
        ]
    }
}
