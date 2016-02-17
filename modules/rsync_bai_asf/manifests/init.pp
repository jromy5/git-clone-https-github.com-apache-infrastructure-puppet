class rsync_bai_asf (
  $secretcontents = '',
) {

  file  { '/etc/rsyncd.secrets':
    content => $secretcontents,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

}
