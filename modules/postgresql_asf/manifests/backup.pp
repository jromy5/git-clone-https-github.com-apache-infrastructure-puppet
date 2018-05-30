# /etc/puppet/modules/postgresql_asf/manifests/backup.pp

class postgresql_asf::backup (
  $dumproot    = '/x1/db_dump/postgres',
  $hour        = '*/4',
  $minute      = 20,
  $age         = '5d',
  $script_path = '/root',
  $script_name = 'dbsave_postgres.sh',
  $user        = 'postgres',
  $group       = 'postgres',
) {

  exec {'check_pgdumproot':
    command => "/bin/mkdir -p ${dumproot}",
    onlyif  => "/usr/bin/test ! -e ${dumproot}",
  }

  file { 'dbsave_postgres.sh':
    ensure  => present,
    path    => "${script_path}/${script_name}",
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => template('postgresql_asf/dbsave_postgres.sh.erb'),
  }

  tidy { 'postgresl-dumps':
    path    => $dumproot,
    age     => $age,
    recurse => true,
    rmdirs  => true,
    type    => 'mtime',
    matches => ['*.sql.gz'],
  }

  cron { 'postgresql dump':
    user    => 'root',
    hour    => $hour,
    minute  => $minute,
    command => "${script_path}/${script_name}",
  }

}
