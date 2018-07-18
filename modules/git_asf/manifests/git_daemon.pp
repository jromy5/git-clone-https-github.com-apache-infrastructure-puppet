#/etc/puppet/modules/git_asf/manifests/git_daemon.pp

class git_asf::git_daemon (
) inherits git_asf {

  include git_asf

  package { $git_asf::daemon_packages:
    ensure => present,
  }

  -> file { 'git daemon config':
    ensure  => present,
    path    => '/etc/default/git-daemon',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('git_asf/git_daemon.erb'),
    notify  => Service['git-daemon'],
  }

  -> service { 'git-daemon':
    ensure     => $git_asf::enable_daemon,
    hasrestart => true,
    hasstatus  => true,
    require    => File['git daemon config'],
  }

}
