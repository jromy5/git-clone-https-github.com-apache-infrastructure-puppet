#/etc/puppet/modules/subversion_server/manifests/board_reminders.pp

class subversion_server::board_reminders (

  $install_path = '/usr/local/bin/board_reminders',
  $packages     = [],

) {

#packages needed 
  package { $packages:
    ensure => installed,
  }

  # File block to deploy fodlers, scripts etc
  file {
    $install_path:
      ensure  => present,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      recurse => true,
      source  => 'puppet:///modules/subversion_server/board_reminders';
  }

  cron {
    'board-reminders':
      minute  => '15',
      hour    => '14',
      weekday => '1',
      user    => 'www-data',
      command => "${install_path}/reminders.pl --cron";
  }
}
