#/etc/puppet/modules/rbldnsd/manifests/master/setup.pp

class rbldnsd::master::setup (

  $RBLDISTDIR  =  '/etc/puppet/modules/rbldnsd/files/rbldnsd',
){

  cron {
    'rbldnsd-sorbs-datafeed':
      ensure  => present,
      require => File[$RBLDISTDIR],
      command => "/usr/bin/rsync -az rsync.nl.sorbs.net::rbldnszones/ ${RBLDISTDIR}/sorbs/ > /dev/null",
      hour    => '*',
      minute  => '15';
    'rbldnsd-spamhaus-sbl-datafeed':
      ensure  => present,
      require => File[$RBLDISTDIR],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/sbl ${RBLDISTDIR}/sbl/ > /dev/null",
      hour    => '*',
      minute  => '20';
    'rbldnsd-spamhaus-xbl-datafeed':
      ensure  => present,
      require => File[$RBLDISTDIR],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/xbl ${RBLDISTDIR}/xbl/ > /dev/null",
      hour    => '*',
      minute  => '25';
    'rbldnsd-spamhaus-pbl-datafeed':
      ensure  => present,
      require => File[$RBLDISTDIR],
      command => "/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/pbl ${RBLDISTDIR}/pbl/ > /dev/null",
      hour    => '*',
      minute  => '30',
  }

  file {
    $RBLDISTDIR:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0770';
  }

}
