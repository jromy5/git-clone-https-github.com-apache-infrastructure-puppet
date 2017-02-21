#/etc/puppet/modules/clamav/manifests/init.pp

class clamav (
  $packages = ['clamav', 'clamsmtp'],

){

  package { $packages:
    ensure => installed,
  }

  service {
    'clamav-daemon':
      ensure  => running,
      require => Service['clamav-freshclam'];
    'clamav-freshclam':
      ensure  => running,
      require => Package[ ['clamav'], ['clamsmtp'] ];
    'clamsmtp':
      ensure  => running,
      require => Package[ ['clamav'], ['clamsmtp'] ];
  }

  file {
    '/etc/clamsmtpd.conf':
      content => template('clamav/clamsmtpd.conf.erb'),
      notify  => Service[ ['clamav-daemon'], ['clamav-freshclam'], ['clamsmtp'] ],
      require => Package[ ['clamav'], ['clamsmtp'] ];
  }
}
