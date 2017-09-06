#/etc/puppet/modules/puppet_asf/manifests.init.pp

class puppet_asf (
  $puppetconf    = '/etc/puppet/puppet.conf',
  $enable_daemon = true,
  $daemon_opts   = '',
  $environment   = 'production',
){

  case $::asfosname {
    ubuntu: {
      case $::lsbdistrelease {
        14.04: {
          package { 'puppet':
            ensure  => '3.8.7-1puppetlabs1',
            require => Apt::Source['puppetlabs', 'puppetdeps'],
            notify  => Service['puppet'],
          }
        }
        16.04: {
          package { 'puppet':
            ensure => 'latest',
            notify => Service['puppet'],
          }
        }
        default: {
        }
      }

      file { 'puppet_daemon_conf':
        ensure  => present,
        path    => '/etc/default/puppet',
        require => Package['puppet'],
        notify  => Service['puppet'],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("puppet_asf/puppet_daemon.${::asfosname}.erb"),
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

  if $::hostname == devops {
    file { $puppetconf :
    ensure  => present,
    require => Package['puppet'],
    notify  => Service['puppet'],
    owner   => 'root',
    group   => 'puppet',
    mode    => '0755',
    content => template("puppet_asf/puppet.${::hostname}.conf.erb"),
    }
  }

  else {
    file { $puppetconf :
      ensure  => present,
      require => Package['puppet'],
      notify  => Service['puppet'],
      owner   => 'root',
      group   => 'puppet',
      mode    => '0755',
      content => template('puppet_asf/puppet.conf.erb'),
    }
  }

}
