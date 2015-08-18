# /etc/puppet/modules/postgresql_asf/manifests/backup.pp

class postgresql_asf::backup (
  $dumproot    = '/x1/db_dump/potgres',
  $hour        = 8,
  $minute      = 20,
  $age         = '5d',
  $script_path = '/root',
  $script_name = 'dbsave_postgres.sh',
  $user        = $postgresql::params::user,
  $group       = $postgresql::params::group,
) {

  file { 'dbsave_postgres.sh':
    ensure  => present,
    path    => "${script_path}/${script_name}",
    owner   => 'root',
    group   => $postgresql::params::group,
    mode    => '0754',
    content => template('postgresql_asf/dbsave_postgres.sh.erb'),
  }

  tidy { 'postgresl-dumps':
    path    => $dumproot,
    age     => $age,
    recurse => true,
    matches => ['*.sql.gz'],
  }

  cron { 'postgresql dump':
    hour    => $hour,
    minute  => $minute,
    command => "${script_path}/${script_name}",
  }

}
