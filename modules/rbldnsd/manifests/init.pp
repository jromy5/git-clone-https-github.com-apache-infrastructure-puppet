#/etc/puppet/modules/rbldnsd/manifests/init.pp

class rbldnsd (
  $packages   = ['rbldnsd'],

){

  package { $packages: 
    ensure   =>  installed,
  }

  cron { 
    'rbldnsd-sorbs-datafeed':
      command  => '/usr/bin/rsync -az rsync.nl.sorbs.net::rbldnszones/ /etc/rbldnsd/sorbs/ > /dev/null',
      hour     => '*',
      minute   => '15';
    'rbldnsd-spamhaus-sbl-datafeed':
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/sbl /etc/rbldnsd/sbl/ > /dev/null',
      hour     => '*',
      minute   => '20';
    'rbldnsd-spamhaus-xbl-datafeed':
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/xbl /etc/rbldnsd/xbl/ > /dev/null',
      hour     => '*',
      minute   => '25';
    'rbldnsd-spamhaus-pbl-datafeed':
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/pbl /etc/rbldnsd/pbl/ > /dev/null',
      hour     => '*',
      minute   => '30',
  }

  file { 
    '/etc/default/rbldnsd':
      owner    => 'root',
      mode     => '0750',
      content  => '';
      require  => [ $packages ];
    '/etc/rbldnsd':
      owner    => 'root',
      mode     => '0750',
      require  => [ $packages ];
  }

}
