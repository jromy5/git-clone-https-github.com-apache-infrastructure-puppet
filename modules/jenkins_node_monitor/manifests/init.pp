#/etc/puppet/modules/jenkins_node_monitor/manifests/init.pp

class jenkins_node_monitor (
  $shell          = '/bin/bash',
  $username       = 'root',
  $group          = 'root',
  $api_key        = '',
){
  require python

  python::pip {
    'datadog' :
      ensure  => present;
  }

  file {
    '/usr/local/etc/jenkins_node_monitor':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/usr/local/etc/jenkins_node_monitor/jnm.py':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/jenkins_node_monitor/jnm.py';
    '/usr/local/etc/jenkins_node_monitor/settings.cfg':
      ensure  => present,
      content => template('jenkins_node_monitor/settings.cfg.erb'),
      owner   => $username,
      group   => $group,
      mode    => '0644';
  }
}
