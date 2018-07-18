#/etc/puppet/modules/puppet_asf/manifests/master.pp

class puppet_asf::master(
  $puppetmaster_enabled_service   = 'apache2',
  $puppetmaster_disabled_service = 'puppetmaster',

) {

  cron { 'updatepuppet':
    command     => 'cd /etc/puppet; ./bin/pull deployment > /dev/null 2>&1',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    user        => 'root',
    minute      => '*/5',
  }

  package { 'puppetmaster':
    ensure  => '3.8.7-1puppetlabs1',
    require => Apt::Source['puppetlabs', 'puppetdeps'],
    notify  => Service[$puppetmaster_enabled_service],
  }

  -> service { $puppetmaster_disabled_service:
    ensure     => stopped,
    notify     => Service[$puppetmaster_enabled_service],
    hasstatus  => true,
    hasrestart => true,
  }

  -> file { '/usr/lib/ruby/vendor_ruby/puppet/reports/foreman.rb':
    ensure  => present,
    require => Package['puppetmaster'],
    notify  => Service[$puppetmaster_enabled_service],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/puppet_asf/foreman.rb'
  }

  -> file { '/etc/puppet/foreman.yaml':
    ensure  => present,
    require => Package['puppetmaster'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0644',
    source  => 'puppet:///modules/puppet_asf/foreman.yaml',
  }

  -> file { 'puppetmaster':
    ensure  => directory,
    require => Package['puppetmaster'],
    path    => '/usr/share/puppet/rack/puppetmasterd',
    owner   => 'puppet',
    group   => 'puppet',
  }

  -> file { '/usr/share/puppet/rack/puppetmasterd/config.ru':
    ensure  => present,
    require => File['puppetmaster'],
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0644',
  }

  -> file  {
    '/usr/share/puppet/rack/puppetmasterd/public':
      ensure  => directory,
      require => File['puppetmaster'],
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0755';
    '/usr/share/puppet/rack/puppetmasterd/tmp':
      ensure  => directory,
      require => File['puppetmaster'],
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0755';
  }

  -> service { $puppetmaster_enabled_service:
    ensure     => running,
    require    => Package['puppetmaster'],
    hasstatus  => true,
    hasrestart => true,
  }

  -> cron { 'clean puppet reports':
    ensure  => present,
    command => 'find /var/lib/puppet/reports/ -type f -iname "*.yaml" -mtime +7 -delete',
    user    => 'root',
    minute  => 7,
  }

}
