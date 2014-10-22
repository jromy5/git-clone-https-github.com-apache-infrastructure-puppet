#/etc/puppet/modules/spamassassin/manifests/init.pp

class spamassassin (

  $spamassassin_packages = [],
  $sa_update             = '/usr/bin/sa-update && /etc/init.d/spamassassin reload',

  $listenip              = '127.0.0.1',
  $allowedips            = '127.0.0.1',
  $required_hits         = '10.0',
  $skip_rbl_checks       = '0',
  $report_safe           = '0',
  $use_bayes             = '0',
  $use_pyzor             = '0',
  $use_razor2            = '0',
  $dns_available         = 'yes',
  $helperhomedir         = '',
  $nouserconfig          = false,
  $allowtell             = false,
  $report_safe           = 1,
  $trusted_networks      = '', # e.g. '192.168.'
  $whitelist_from        = [],
  $blacklist_from        = [],

  $custom_scoring        = [],
  $custom_rules          = [],


) {

  file { 'spamfilter.sh':
    ensure => present,
    path => '/usr/bin/spamfilter.sh',
    owner => 'root',
    group => 'root',
    mode => '0755',
    source => 'puppet:///modules/spamassassin/spamfilter.sh',
  }
  package { $spamassassin_packages: 
    ensure   =>  installed,
  }

  cron { 'sa-update':
    command => $sa_update,
    user    => 'root',
    hour    => 2,
    minute  => 10,
  }

  service { 'spamassassin':
    ensure  => running,
    enable  => true,
    require => Package[ $spamassassin_packages ],
    pattern => 'spamd',
  }

  file { 
         '/etc/mail/spamassassin/local.cf':
           content => template('spamassassin/local.cf.erb'),
           require => Package[ $spamassassin_packages ],
           notify  => Service['spamassassin'];
         '/etc/mail/spamassassin/init.pre':
           content => template('spamassassin/init.pre.erb'),
           require => Package[ $spamassassin_packages ],
           notify  => Service['spamassassin'];
       }

  if $::osfamily == 'Debian' {
    file { '/etc/default/spamassassin':
      content => template('spamassassin/spamassassin-default.erb'),
      require => Package[ $spamassassin_packages ],
      notify  => Service['spamassassin'],
    }
  }

}
