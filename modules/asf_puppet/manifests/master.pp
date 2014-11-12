class puppet::master {

  cron { updatepuppet:
    command => "cd /etc/puppet; /usr/bin/git pull",
    user    => root,
    minute  => '*/5',
  }

  package { 'puppetmaster':
    ensure  => '3.6.2-1puppetlabs1',
    require => apt::source['puppetlabs', 'puppetdeps'],
  }

  service { 'puppetmaster':
    require    => package['puppetmaster']
    hasstatus  => true,
    hasrestart => true,
    ensure     => running,
  }

  file { "/usr/lib/ruby/vendor_ruby/puppet/reports/foreman.rb":
   ensure  => 'present',
   require => Package["puppet"],
   notify  => Service["puppetmaster"],
   owner   => "root",
   group   => "puppet",
   mode    => 755,
   source  => "puppet:///modules/asf_puppet/foreman.rb"
  }

}
