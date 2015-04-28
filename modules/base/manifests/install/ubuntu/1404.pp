class base::install::ubuntu::1404 (
) {

  file {
    '/root':
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
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
}
