class puppet (
  $puppetconf  = '/etc/puppet/puppet.conf'
){

  package { 'puppet':
    ensure  => '3.6.2-1puppetlabs1',
    require => apt::source['puppetlabs', 'puppetdeps'],
  }

  service { 'puppet':
    require => package['puppet'],
    hasstatus => true,
    hasrestart => true,
    enable => true,
    ensure => running,
  }

 file { "${puppetconf}" :
   ensure  => 'present',
   require => Package["puppet"],
   notify  => Service["puppet"],
   owner   => "root",
   group   => "puppet",
   mode    => 755,
   source  => [ 
     "puppet:///modules/puppet/puppet.$hostname.conf",
     "puppet:///modules/puppet/puppet.conf",
     ]
  }

}
