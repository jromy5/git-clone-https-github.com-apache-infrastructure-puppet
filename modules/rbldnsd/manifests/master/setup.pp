#/etc/puppet/modules/rbldnsd/manifests/master/setup.pp

class rbldnsd::master::setup (

){

  cron { 
    'rbldnsd-sorbs-datafeed':
      ensure   => present,
      require  => File['/var/rbldnsd'],
      command  => '/usr/bin/rsync -az rsync.nl.sorbs.net::rbldnszones/ /var/rbldnsd/sorbs/ > /dev/null',
      hour     => '*',
      minute   => '15';
    'rbldnsd-spamhaus-sbl-datafeed':
      ensure   => present,
      require  => File['/var/rbldnsd'],
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/sbl /var/rbldnsd/sbl/ > /dev/null',
      hour     => '*',
      minute   => '20';
    'rbldnsd-spamhaus-xbl-datafeed':
      ensure   => present,
      require  => File['/var/rbldnsd'],
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/xbl /var/rbldnsd/xbl/ > /dev/null',
      hour     => '*',
      minute   => '25';
    'rbldnsd-spamhaus-pbl-datafeed':
      ensure   => present,
      require  => File['/var/rbldnsd'],
      command  => '/usr/bin/rsync -az rsync://rsync1.spamhaus.org/rbldnsd/pbl /var/rbldnsd/pbl/ > /dev/null',
      hour     => '*',
      minute   => '30',
  }

  file {
    '/var/rbldnsd':
      ensure   => 'directory',
      owner    => 'root',
      group    => 'rbldns',
      mode     => '0770',
  }

}
