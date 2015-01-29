class puppet_asf::master {

  cron { 'updatepuppet':
    command     => 'cd /etc/puppet; ./bin/pull > /dev/null 2>&1',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    user        => 'root',
    minute      => '*/5',
  }

  package { 'puppetmaster':
    ensure  => '3.6.2-1puppetlabs1',
    require => Apt::Source['puppetlabs', 'puppetdeps'],
  }

  service { 'puppetmaster':
    ensure     => running,
    require    => Package['puppetmaster'],
    hasstatus  => true,
    hasrestart => true,
  }

  file { '/usr/lib/ruby/vendor_ruby/puppet/reports/foreman.rb':
    ensure  => present,
    require => Package['puppetmaster'],
    notify  => Service['puppetmaster'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/puppet_asf/foreman.rb'
  }

  file { '/etc/puppet/foreman.yaml':
    ensure  => present,
    require => Package['puppetmaster'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0644',
    source  => 'puppet:///modules/puppet_asf/foreman.yaml',
  }

  file { 'puppetmaster':
    require => Package['puppetmaster'],
    path    => '/usr/share/puppet/rack/puppetmasterd',
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
  }

  file { '/usr/share/puppet/rack/puppetmasterd/config.ru':
    require => File['puppetmaster'],
    ensure  => present,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0644',
  }

  $puppet_dirs = [
    '/usr/share/puppet/rack/puppetmasterd/public',
    '/usr/share/puppet/rack/puppetmasterd/tmp',
  ]

  file  { $puppet_dirs:
    require => File['puppetmaster'],
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
  }

}
