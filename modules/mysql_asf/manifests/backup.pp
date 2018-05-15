#/etc/puppet/modules/mysql_asf/manifests/backup.pp


class mysql_asf::backup (
  $script_path   = '/root',
  $script_name   = 'dbsave_mysql.sh',
  $hour          = 03,
  $minute        = 45,
  $dumproot      = '/x1/db_dump/mysql',
  $age           = '5d',
  $rsync_offsite = 'false', # copy to bai if true, requires setup
  $rsync_user    = 'apb-mysql',
  $rsync_passwd  = '', # set in eyaml if rsync_offsite
) {

  require stunnel_asf
  require mysql::server

  file {
    'dbsave.sh':
      path    => "${script_path}/${script_name}",
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      content => template('mysql_asf/dbsave_mysql.sh.erb'),
  }

  if $rsync_offsite == 'true' {
    file {
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
      }
  }

  tidy { 'mysql-dumps':
    path    => $dumproot,
    age     => $age,
    recurse => true,
    matches => ['*.sql.gz'],
  }

  cron { 'mysql-dump-rsync-to-abi':
    hour    => $hour,
    minute  => $minute,
    command => "${script_path}/${script_name}",
  }
}
