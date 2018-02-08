#/etc/puppet/modules/tac_asf/manifests/init.pp

class tac_asf (

  $username   = 'tac',
  $groupname  = 'tac',

  # override below in yaml

  $parent_dir,

  # below are contained in eyaml

  $tac_dbpasswd = '',
  $tac_dbuser = '',
  $tac_dbhost = '',
  $tac_dbport = '',

  # rsync backups to bai
  $rsync_passwd = '',

){

$install_dir    = "${parent_dir}/tac_app"
$django_version = '1.3'

  user {
    $username:
      ensure  => present,
      system  => true,
      name    => $username,
      gid     => $groupname,
      require => Group[$groupname],
  }

  group {
    $groupname:
      ensure => present,
      system => true,
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => $username,
      group  => $groupname,
      mode   => '0755';
    $install_dir:
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      require => File[$parent_dir];
    "${parent_dir}/tac_app.wsgi":
      owner   => $username,
      group   => $groupname,
      content => template('tac_asf/tac_app.wsgi.erb'),
      mode    => '0755';
    "${install_dir}/local_settings.py":
      owner   => $username,
      group   => $groupname,
      content => template('tac_asf/local_settings.py.erb'),
      mode    => '0750';
    '/root/rsynclogs':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700';
    '/root/.pw-abi':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $rsync_passwd;
    '/root/tac-daily-bai.sh':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
      source => 'puppet:///modules/tac_asf/tac-daily-bai.sh';
  }

  cron {
    'tac_daily_bai':
      command => '/root/tac-daily-bai.sh',
      user    => 'root',
      hour    => '18',
      minute  => '30',
  }

}
