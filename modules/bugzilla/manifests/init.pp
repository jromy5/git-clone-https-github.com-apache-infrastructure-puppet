
class bugzilla (
) {

  require apache
  require rootbin_asf

  file { ["/etc/bugzilla", "/etc/bugzilla/.puppet"]:
    ensure => directory,
    mode   => 0755,
    owner  => "root",
    group  => "root",
  }

  cron { 'bugcron':
    command => '/root/bin/bugcron.sh',
    user    => 'root',
    minute  => 15,
    hour    => 7,
    weekday => 0,
   environment => 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SHELL=/bin/sh',
    require => Class['rootbin_asf'],
  }

}
