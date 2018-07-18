#/etc/puppet/modules/base/manifests/install/ubuntu/ubuntu_1404.pp

class base::install::ubuntu::ubuntu_1404 (
) {

  file {
    '/root':
      owner => 'root',
      group => 'root',
      mode  => '0755';
    '/root/purge_old_kernels':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0754',
      source => 'puppet:///modules/base/purge_old_kernels';
    '/usr/local/bin/zsh':
      ensure => link,
      target => '/usr/bin/zsh';
    '/usr/local/bin/bash':
      ensure => link,
      target => '/bin/bash';
    '/etc/logrotate.d/rsyslog':
      ensure => present,
      source => 'puppet:///modules/base/logrotate-rsyslog';
  }

  -> cron {
    'purge_old_kernels':
      ensure      => present,
      command     => '/bin/sh /root/purge_old_kernels -y > /dev/null',
      environment => 'MAILTO=""',
      minute      => '10',
      hour        => '0',
      weekday     => '0',
      require     => File['/root/purge_old_kernels'];
    'delete state.yaml':
      ensure  => present,
      command => 'rm -f /var/lib/puppet/state/state.yaml',
      hour    => '0';
  }
}
