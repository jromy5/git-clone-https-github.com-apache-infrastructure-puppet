#/etc/puppet/modules/gump_server/manifests/cronjobs.pp

class gump_server::cronjobs {

  cron {
    'Clean up older artifacts':
      ensure  => present,
      command => '/usr/bin/find /srv/gump/public/workspace/repo -type f -ctime +6 | /usr/bin/xargs -r /bin/rm > /dev/null 2>&1',
      user    => gump,
      hour    => 0,
      minute  => 0;

    'Clean up after POI and other tests':
      ensure  => present,
      command => '/usr/bin/find /tmp -type f -ctime +6 | /usr/bin/xargs -r /bin/rm > /dev/null 2>&1',
      user    => gump,
      hour    => 0,
      minute  => 0;

    'Clean up logs older than about a month':
      ensure  => present,
      command => '/usr/bin/find /srv/gump/public/gump/log -type f -ctime +15 | /usr/bin/xargs -r /bin/rm > /dev/null 2>&1',
      user    => gump,
      hour    => 0,
      minute  => 0;

    'Public - these are subruns of public that don\'t send email but update the web site':
      ensure  => present,
      command => 'cd /srv/gump/public/gump/cron; /bin/bash gump.sh all',
      user    => gump,
      hour    => [6,12,18],
      minute  => 0;

    'Official Gump run sending out nag mails':
      ensure  => present,
      command => 'cd /srv/gump/public/gump/cron; /bin/bash gump.sh all --official',
      user    => gump,
      hour    => 0,
      minute  => 0;
  }
}
