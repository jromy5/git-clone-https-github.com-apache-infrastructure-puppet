# rsync to bai class containing default empty secrets variable.
class rsync_bai_asf (
  $secretcontents = '',
) {

  file  { '/etc/rsyncd.secrets':
    content => $secretcontents,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  cron  { 'zfs-snapshot-bai':
    command => '/root/bin/zfs-snapshot-bai.sh tank/x1/backups',
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }

}
