# == Class: spamassassin
#
# This module manages spamassassin
#
class spamassassin::spamd (
  $allowedips       = '127.0.0.1',
  $allowtell        = false,
  $blacklist_from   = [],
  $createprefs      = false,
  $cron_ensure      = present,
  $helperhomedir    = '',
  $install_folder   = '/etc/mail/spamassassin',
  $listenip         = '127.0.0.1',
  $local            = false,
  $maxchildren      = 5,
  $maxconnperchild  = 200,
  $maxspare         = 2,
  $minchildren      = 1,
  $minspare         = 2,
  $nouserconfig     = false,
  $package_ensure   = latest,
  $package_list     = [],
  $report_safe      = 1,
  $roundrobin       = false,
  $sa_update        = ''
  $service_enable   = true,
  $service_ensure   = running,
  $syslog           = 'mail',
  $trusted_networks = '', # e.g. '192.168.'
  $whitelist_from   = [],

) {

  package { $package_list:
    ensure => $package_ensure,
  }

  file { "${install_folder}/init.pre":
    source  => 'puppet:///modules/spamassassin/init.pre',
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  file { "${install_folder}/local.cf":
    content => template('spamassassin/local.cf.erb'),
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  file { "${install_folder}/v310.pre":
    source  => 'puppet:///modules/spamassassin/v310.pre',
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  file { "${install_folder}/v312.pre":
    source  => 'puppet:///modules/spamassassin/v312.pre',
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  file { "${install_folder}/v320.pre":
    source  => 'puppet:///modules/spamassassin/v320.pre',
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  file { "${install_folder}/v330.pre":
    source  => 'puppet:///modules/spamassassin/v330.pre',
    require => Package[ $package_list ],
    notify  => Service['spamassassin']
  }

  if $::osfamily == 'Debian' {
    file { '/etc/default/spamassassin':
      content => template('spamassassin/spamassassin-default.erb'),
      require => Package['spamassassin'],
      notify  => Service['spamassassin'],
    }
  }

  cron { 'sa-update':
    ensure  => $cron_ensure,
    command => $sa_update,
    user    => 'root',
    hour    => 2,
    minute  => 10,
  }

  service { 'spamassassin':
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => Package['spamassassin'],
    pattern => 'spamd',
  }
}
