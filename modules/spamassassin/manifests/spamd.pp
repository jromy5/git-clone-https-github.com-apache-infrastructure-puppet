# == Class: spamassassin
#
# This module manages spamassassin
#
class spamassassin::spamd (
  $allowedips            = '127.0.0.1',
  $allowtell             = false,
  $blacklist_from        = [],
  $createprefs           = false,
  $cron_ensure           = present,
  $custom_rules          = [],
  $custom_scoring        = {},
  $dns_available         = 'yes',
  $helperhomedir         = '',
  $install_folder        = '/etc/spamassassin',
  $kam_update            = '/usr/bin/curl http://www.pccc.com/downloads/SpamAssassin/contrib/KAM.cf -o /etc/spamassassin/KAM.cf && /usr/bin/spamassassin --lint && /usr/sbin/service spamassassin restart',
  $listenip              = '127.0.0.1',
  $local                 = false,
  $maxchildren           = 40,
  $maxconnsperchild      = 1000,
  $maxspare              = 10,
  $minchildren           = 5,
  $minspare              = 1,
  $nouserconfig          = false,
  $package_ensure        = latest,
  $package_list          = [],
  $report_safe           = 1,
  $required_hits         = '10.0',
  $roundrobin            = false,
  $sa_update             = '/usr/bin/sa-update && /etc/init.d/spamassassin reload',
  $service_enable        = true,
  $service_ensure        = running,
  $skip_rbl_checks       = '0',
  $syslog                = 'mail',
  $trusted_networks      = '127.0.0.1', # e.g. '192.168.'
  $use_bayes             = '0',
  $use_pyzor             = '0',
  $use_razor2            = '0',
  $whitelist_from        = [],



) {

  package { $package_list:
    ensure => $package_ensure,
  }

  ## SpamAssassin Files
  file {
    "${install_folder}/init.pre":
      source  => 'puppet:///modules/spamassassin/init.pre',
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
    "${install_folder}/local.cf":
      content => template('spamassassin/local.cf.erb'),
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
    "${install_folder}/v310.pre":
      source  => 'puppet:///modules/spamassassin/v310.pre',
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
    "${install_folder}/v312.pre":
      source  => 'puppet:///modules/spamassassin/v312.pre',
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
    "${install_folder}/v320.pre":
      source  => 'puppet:///modules/spamassassin/v320.pre',
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
    "${install_folder}/v330.pre":
      source  => 'puppet:///modules/spamassassin/v330.pre',
      require => Package[ $package_list ],
      notify  => Service['spamassassin'];
  }
  
  ## Amavis Files
  file {
    '/etc/amavis/conf.d':
      ensure  => present,
      source  => 'puppet:///modules/spamassassin/amavis/',
      recurse => true,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      notify  => Service['amavis'];
    '/etc/amavis/conf.d/50-user':
      content => template('spamassassin/amavis/50-user.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      notify  => Service['amavis'];
  }

  if $::osfamily == 'Debian' {
    file { '/etc/default/spamassassin':
      content => template('spamassassin/spamassassin-default.erb'),
      require => Package['spamassassin'],
      notify  => Service['spamassassin'],
    }
  }

  cron {
    'sa-update':
      ensure  => $cron_ensure,
      command => $sa_update,
      user    => 'root',
      hour    => 2,
      minute  => 10;
    'fetch-pccc_KAM.cf':
      ensure  => $cron_ensure,
      command => $kam_update,
      user    => 'root',
      hour    => '1',
      minute  => '30';
  }

  service {
    'spamassassin':
      ensure     => $service_ensure,
      enable     => $service_enable,
      require    => Package['spamassassin'],
      pattern    => 'spamd',
      hasstatus  => true,
      hasrestart => true;
    'amavis':
      ensure     => $service_ensure,
      enable     => $service_enable,
      require    => Package['amavisd-new'],
      hasstatus  => true,
      hasrestart => true;
    'clamav-daemon':
      ensure     => $service_ensure,
      enable     => $service_enable,
      require    => Package['clamav-daemon'],
      hasstatus  => true,
      hasrestart => true;
    'clamsmtp':
      ensure     => $service_ensure,
      enable     => $service_enable,
      require    => Package['clamsmtp'],
      hasstatus  => false,
      hasrestart => true;
  }


  group {
    'amavis':
      members => 'clamav',
      require => Package['amavisd-new'];
    'clamav':
      members => 'amavis',
      require => Package['clamav-daemon'],
  }
}
