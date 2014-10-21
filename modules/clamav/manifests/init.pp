#/etc/puppet/modules/clamav/manifests/init.pp

class clamav (
  $packages   = ['clamav', 'clamsmtp'],

){

  package { $packages: 
    ensure   =>  installed,
  }

  service {
    'clamav-daemon': 
      ensure  => running,
      require => Package[ ['clamav'], ['clamsmtp'] ];
    'clamav-freshclam':
      ensure  => running,
      require => Package[ ['clamav'], ['clamsmtp'] ];
    'clamavsmtp':
      ensure  => running,
      require => Package[ ['clamav'], ['clamsmtp'] ];
  }

  file { 
    '/etc/clamsmtpd.conf':
      content => template('clamav/clamsmtpd.conf.erb'),
      notify  => Service[ ['clamav-daemon'], ['clamav-freshclam'], ['clamavsmtp'] ],
      require => Package[ ['clamav'], ['clamsmtp'] ];
  }
}
