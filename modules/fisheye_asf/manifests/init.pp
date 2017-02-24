#/etc/puppet/modules/fisheye_asf/manifests/init.pp

class fisheye_asf (
  $group_present                 = 'present',
  $groupname                     = 'fisheye',
  $groups                        = [],
  $service_ensure                = 'stopped',
  $service_name                  = 'fisheye',
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'fisheye',

  # override below in yaml
  $fisheye_version               = '',
  #$mysql_connector_version       = '',
  $parent_dir,
  $server_port                   = '',
  $connector_port                = '',
  $context_path                  = '',

  $required_packages             = ['unzip','wget','libmysql-java'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

  file { 'fisheye profile':
    ensure  => 'present',
    path    => "/home/${username}/.profile",
    mode    => '0644',
    owner   => $username,
    group   => $groupname,
    source  => 'puppet:///modules/fisheye_asf/home/profile',
    require => User[$username],
  }

# fisheye specific
  $fisheye_build            = "fisheye-${fisheye_version}"
  $zip                      = "${fisheye_build}.zip"
  $download_dir             = '/tmp'
  $downloaded_zip           = "${download_dir}/${zip}"
  $download_url             = "https://www.atlassian.com/software/fisheye/downloads/binary/${zip}"
  $install_dir              = "${parent_dir}/${fisheye_build}"
  $fisheye_home             = "${parent_dir}/fisheye-data"
  $current_dir              = "${parent_dir}/current"

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "/home/${username}",
      shell      => $shell,
      groups     => $groups,
      gid        => $groupname,
      managehome => true,
      require    => Group[$groupname],
      system     => true,
  }

  group {
    $groupname:
      ensure => $group_present,
      system => true,
  }

# download standalone Fisheye
  exec {
    'download-fisheye':
      command => "/usr/bin/wget -O ${downloaded_zip} ${download_url}",
      creates => $downloaded_zip,
      timeout => 1200,
  }

  file { $downloaded_zip:
    ensure  => file,
    require => Exec['download-fisheye'],
  }


# extract the download and move it
  exec {
    'extract-fisheye':
      # take out the hardcoded fecru bits
      command => "/usr/bin/unzip ${zip} && sudo mkdir ${parent_dir}/${fisheye_build} && sudo mv fecru-${fisheye_version}/* ${parent_dir}/${fisheye_build}", # lint:ignore:140chars
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/README.html",
      timeout => 1200,
      require => [File[$downloaded_zip],File[$parent_dir]],
  }

# copy the original config.xml to the instance dir
  exec {
    'copy-config':
      command => "/bin/cp ${install_dir}/config.xml ${fisheye_home}/config.xml",
      user    => 'fisheye',
      creates => "${fisheye_home}/config.xml",
      timeout => 600,
      require => [Exec['extract-fisheye'],File[$fisheye_home]],
  }

file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $fisheye_home:
      ensure  => directory,
      owner   => 'fisheye',
      group   => 'fisheye',
      mode    => '0755',
      require => File[$install_dir];
    $install_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Exec['extract-fisheye'];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$install_dir];
    "${fisheye_home}/lib":
      ensure  => directory,
      owner   => 'fisheye',
      group   => 'fisheye',
      mode    => '0755',
      require => File[$fisheye_home];
    "${fisheye_home}/lib/mysql-connector-java-5.1.38.jar":
      ensure  => link,
      target  => '/usr/share/java/mysql-connector-java-5.1.38.jar',
      require => Package['libmysql-java'];
    "/home/${username}/.subversion":
      ensure  => directory,
      owner   => 'fisheye',
      group   => 'fisheye',
      mode    => '0755',
      require => [Package['subversion'],User[$username]];
    "/home/${username}/.subversion/servers":
      ensure  => present,
      owner   => 'fisheye',
      group   => 'fisheye',
      mode    => '0644',
      source  => 'puppet:///modules/fisheye_asf/home/subversion/servers',
      require => [Package['subversion'],File["/home/${username}/.subversion"]];
  }

  ::systemd::unit_file { 'fisheye.service':
      source => 'puppet:///modules/fisheye_asf/fisheye.service',
  }
}
