class puppet_asf (
  $puppetconf    = '/etc/puppet/puppet.conf',
  $enable_daemon = true,
  $daemon_opts   = '',
){

  case $asfosname {
    ubuntu: {
      package { 'puppet':
        ensure  => '3.7.5-1puppetlabs1',
        require => Apt::Source['puppetlabs', 'puppetdeps'],
        notify  => Service['puppet'],
      }

      file { 'puppet_daemon_conf':
        ensure  => present,
        path    => '/etc/default/puppet',
        require => Package['puppet'],
        notify  => Service['puppet'],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("puppet_asf/puppet_daemon.${asfosname}.erb"),
      }

    }
    centos: {
      package { 'puppet':
        ensure  => '3.7.4-1.el6',
        require => Yumrepo['puppetlabs-products', 'puppetlabs-deps'],
      }
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  service { 'puppet':
    ensure     => running,
    require    => Package['puppet'],
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
  }

  file { $puppetconf :
    ensure  => present,
    require => Package['puppet'],
    notify  => Service['puppet'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
    source  => [
      "puppet:///modules/puppet_asf/puppet.${hostname}.conf",
      "puppet:///modules/puppet_asf/${asfosname}.puppet.conf",
      'puppet:///modules/puppet_asf/puppet.conf',
    ]
  }

}
