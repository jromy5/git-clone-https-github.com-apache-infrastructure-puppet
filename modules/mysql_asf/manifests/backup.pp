
class mysql_asf::backup (
  $script_path = '/root',
  $script_name = 'dbsave_mysql.sh',
  $hour        = 22,
  $minute      = 45,
) {
  
  require mysql::server

  file { "dbsave.sh":
    path    => "${script_path}/${script_name}",
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('mysql_asf/dbsave_mysql.sh.erb'),
  }

  cron { 'mysql-dump-rsync-to-abi':
    hour    => 22,
    minute  => 45,
    command => "${script_path}/${script_name}",
  }

}
