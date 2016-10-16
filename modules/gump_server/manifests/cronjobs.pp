#/etc/puppet/modules/gump_server/manifests/cronjobs.pp

class gump_server::cronjobs {

  cron { 'Clean up older artifacts':
    ensure => present,
    command => "/usr/bin/find /srv/gump/public/workspace/repo -type f -ctime +6 | /usr/bin/xargs -r /bin/rm > /dev/null 2>&1",
    user => gump,
    hour => '0',
    minute => '0',
  }

  cron { 'Clean up after POI and other tests':
    ensure => present,
    command => "/usr/bin/find /tmp -type f -ctime +6 | /usr/bin/xargs -r /bin/rm > /dev/null 2>&1",
    user => gump,
    hour => '0',
    minute => '0',
  }
}
