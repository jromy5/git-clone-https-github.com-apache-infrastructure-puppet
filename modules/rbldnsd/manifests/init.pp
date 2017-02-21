#/etc/puppet/modules/rbldnsd/manifests/init.pp

class rbldnsd (
  $packages = ['rbldnsd'],

){

  package { $packages:
    ensure => installed,
  }

  cron {
    'rbldnsd-sorbs-datafeed':
      ensure  => absent,
      command => '/usr/bin/rsync -az rsync.nl.sorbs.net::rbldnszones/ /etc/rbldnsd/sorbs/ > /dev/null',
      hour    => '*',
      minute  => '15';
    'rbldnsd-spamhaus-sbl-datafeed':
      ensure  => absent,
      command => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/sbl /etc/rbldnsd/sbl/ > /dev/null',
      hour    => '*',
      minute  => '20';
    'rbldnsd-spamhaus-xbl-datafeed':
      ensure  => absent,
      command => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/xbl /etc/rbldnsd/xbl/ > /dev/null',
      hour    => '*',
      minute  => '25';
    'rbldnsd-spamhaus-pbl-datafeed':
      ensure  => absent,
      command => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/pbl /etc/rbldnsd/pbl/ > /dev/null',
      hour    => '*',
      minute  => '30',
  }

  file {
    '/etc/default/rbldnsd':
      owner   => 'root',
      mode    => '0750',
      content => 'RBLDNSD="dsbl -b 127.0.0.1 -r /etc/rbldnsd -t 21600 -c 30 sbl-xbl-pbl.spamhaus.org:ip4set:sbl/sbl sbl-xbl-pbl.spamhaus.org:ip4set:xbl/xbl sbl-xbl-pbl.spamhaus.org:ip4set:pbl/pbl dul.dnsbl.sorbs.net:ip4set:sorbs/dul.dnsbl.sorbs.net dul.dnsbl.sorbs.net:generic:sorbs/generic.sorbs.net dnsbl.apache.org:ip4set:dnsbl.apache.org"', # lint:ignore:140chars
      notify  => Service['rbldnsd'];
    '/etc/rbldnsd':
      ensure => 'directory',
      owner  => 'root',
      group  => 'rbldns',
      mode   => '0770',
      notify => Service['rbldnsd'];
  }

  service {
    'rbldnsd':
      ensure => 'running',
  }
}
