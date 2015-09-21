#/etc/puppet/modules/rbldnsd/manifests/master/setup.pp

class rbldnsd::master::setup (

  $rbldistdir = '/etc/puppet/modules/rbldnsd/files/rbldnsd',
){

  cron {
    'rbldnsd-sorbs-datafeed':
      ensure  => present,
      require => File[$rbldistdir],
      command => "/usr/bin/rsync -az rsync://rsync.sorbs.net ${rbldistdir}/sorbs/ > /dev/null", # lint:ignore:80chars
      hour    => '*',
      minute  => '15';
    'rbldnsd-spamhaus-sbl-datafeed':
      ensure  => present,
      require => File[$rbldistdir],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/sbl ${rbldistdir}/sbl/ > /dev/null", # lint:ignore:80chars
      hour    => '*',
      minute  => '20';
    'rbldnsd-spamhaus-xbl-datafeed':
      ensure  => present,
      require => File[$rbldistdir],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/xbl ${rbldistdir}/xbl/ > /dev/null", # lint:ignore:80chars
      hour    => '*',
      minute  => '25';
    'rbldnsd-spamhaus-pbl-datafeed':
      ensure  => present,
      require => File[$rbldistdir],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/pbl ${rbldistdir}/pbl/ > /dev/null", # lint:ignore:80chars
      hour    => '*',
      minute  => '30',
  }

  file {
    $rbldistdir:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0770';
  }

}
