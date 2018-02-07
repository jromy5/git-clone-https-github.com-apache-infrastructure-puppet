#/etc/puppet/modules/tac_asf/manifests/init.pp

class tac_asf (

  $username   = 'tac',
  $groupname  = 'tac',

  # override below in yaml

  $parent_dir,

  # below are contained in eyaml

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
  }
}
