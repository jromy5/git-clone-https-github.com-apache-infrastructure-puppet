#/etc/puppet/modules/mail_archives/manifests.init.pp

class mail_archives (

  $username   = 'modmbox',
  $groupname  = 'modmbox',
  $shell      = '/bin/bash',

  # override below in yaml
  $parent_dir,

){

  $install_dir = "${parent_dir}/mail-archives"

  group {
    $groupname:
      ensure => present,
      system => true,
  }->

  user {
    $username:
      ensure  => present,
      system  => true,
      name    => $username,
      shell   => $shell,
      gid     => $groupname,
      require => Group[$groupname],
  }

  file {
    $install_dir:
      ensure => directory,
      owner  => $username,
      group  => 'root';
    "${install_dir}/raw":
      ensure => directory,
      mode   => '0755';
  }

}
