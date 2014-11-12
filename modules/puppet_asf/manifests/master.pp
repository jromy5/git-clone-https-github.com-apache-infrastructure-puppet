class puppet_asf::master {
  include puppet_asf
  cron { 'updatepuppet':
    command => 'cd /etc/puppet; /usr/bin/git pull',
    user    => root,
    minute  => '*/5',
  }

  package { 'puppetmaster':
    ensure  => '3.6.2-1puppetlabs1',
    require => apt::source['puppetlabs', 'puppetdeps'],
  }

  service { 'puppetmaster':
    ensure     => running,
    require    => package['puppetmaster'],
    hasstatus  => true,
    hasrestart => true,
  }

  file { '/usr/lib/ruby/vendor_ruby/puppet/reports/foreman.rb':
    ensure  => 'present',
    require => Package['puppet'],
    notify  => Service['puppetmaster'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/puppet_asf/foreman.rb'
  }

  file { '/etc/puppet/foreman.yaml':
    ensure  => 'present',
    require => Package['puppet'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '644',
    source  => 'puppet:///modules/puppet_asf/foreman.yaml',
  }
}
