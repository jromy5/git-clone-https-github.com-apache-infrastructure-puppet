# modules/projects_pvm_asf/manifests/init.pp

class projects_pvm_asf (

) {

  # ensure log file directories exist
  file {
    '/var/log/www-data':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0775';

    '/var/log/www-data-root':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0775';
  }

  cron {

  # WARNING: the percent character is special in a crontab; it must be escaped with a backslash

  # Note: svn add is done by www-data cronjobs running at 40 mins past the hour
  # SVN checkins must run as www-data otherwise the www-data user may have problems issuing SVN commands

  # Check in any updated data/releases files
    'rao_releases_ci':
      minute  => 45,
      hour    => [0, 6, 12, 18],
      user    => 'root',
      require => File['/var/log/www-data-root'],
      command => 'cd /var/www/reporter.apache.org/data/releases && sudo -n -u www-data svn ci -m "updating report releases data" --username projects_role --password `cat /root/.rolepwd` --non-interactive >>/var/log/www-data-root/svnreleases_$(date "+\%Y-\%m").log 2>&1'; # lint:ignore:140chars

  #
  # Check in any updated data/history files
  # These are copied extracts of the files created by parsepmcs.py which is run at 00 min 4,12,20 hours
    'rao_history_ci':
      minute  => 10,
      hour    => [4, 12, 20],
      user    => 'root',
      require => File['/var/log/www-data-root'],
      command => 'cd /var/www/reporter.apache.org/data/history && sudo -n -u www-data svn ci -m "updating report releases data" --username projects_role --password `cat /root/.rolepwd` --non-interactive >>/var/log/www-data-root/svnhistory_$(date "+\%Y-\%m").log 2>&1'; # lint:ignore:140chars
  #
  # Check in any updated/new json files under projects.apache.org
  # The "svn add" job run under www-data is run at 04:10
    'pao_json_ci':
      minute  => 20,
      hour    => 4,
      user    => 'root',
      require => File['/var/log/www-data-root'],
      command => 'cd /var/www/projects.apache.org/site/json && sudo -n -u www-data svn ci -m "updating projects data" --username projects_role --password `cat /root/.rolepwd` --non-interactive >>/var/log/www-data-root/svnjson_$(date "+\%Y-\%m").log 2>&1'; # lint:ignore:140chars

  }

}
