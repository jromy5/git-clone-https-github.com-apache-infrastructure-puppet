#/etc/puppet/modules/rbldnsd/manifests/client/setup.pp

class rbldnsd::client::setup (
  $packages = ['rbldnsd'],

){

  package {
    $packages:
      ensure => installed,
  }


  file {
    '/etc/default/rbldnsd':
      owner   => 'root',
      mode    => '0750',
      content => 'RBLDNSD="dsbl -b 127.0.0.1 -r /etc/rbldnsd -t 21600 -c 30 sbl-xbl-pbl.spamhaus.org:ip4set:sbl/sbl sbl-xbl-pbl.spamhaus.org:ip4set:xbl/xbl sbl-xbl-pbl.spamhaus.org:ip4set:pbl/pbl dul.dnsbl.sorbs.net:ip4set:sorbs/dul.dnsbl.sorbs.net dul.dnsbl.sorbs.net:generic:sorbs/generic.sorbs.net"', # lint:ignore:140chars
      notify  => Service['rbldnsd'];

    '/etc/rbldnsd':
      ensure  => 'directory',
      owner   => 'root',
      group   => 'rbldns',
      backup  => false,
      mode    => '0770',
      recurse => true,
      source  => 'puppet:///modules/rbldnsd/rbldnsd/',
      notify  => Service['rbldnsd'];
  }

  service { 'rbldnsd':
    ensure  => 'running',
    require => File['/etc/rbldnsd'],
    pattern => 'rbldnsd',
  }
}
