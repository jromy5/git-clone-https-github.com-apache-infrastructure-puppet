# deploy rsync-offsite script

class rsync_asf (
  $scriptpath   = '/root/rsync-offsite.sh',
  $dumplist     = '/root/dumplist',
  $fslist       = [ '/x1' , '/x2' ], # override in yaml
  $rsync_passwd = '', # eyaml
){

  include stdlib

  file {
    'rsync-offsite.sh':
      path    => $scriptpath,
      ensure  => present,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('rsync_asf/rsync-offsite.sh.erb');
    $dumplist:
      path    => $dumplist,
      ensure  => present,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => join($fslist,"\n");
    '/root/.pw-abi':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $rsync_passwd;
  }

}
