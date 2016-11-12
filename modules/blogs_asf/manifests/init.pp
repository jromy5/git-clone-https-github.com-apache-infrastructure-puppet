#/etc/puppet/modules/blogs_asf/manifests/init.pp

class blogs_asf (
  $r_uid             = 8998,
  $r_gid             = 8998,
  $r_group_present   = 'present',
  $r_groupname       = 'roblogs',
  $t_uid             = 8997,
  $t_gid             = 8997,
  $t_group_present   = 'present',
  $t_groupname       = 'tcblogs',
  $groups            = [],
  $service_ensure    = 'stopped',
  $service_name      = 'roller',
  $shell             = '/bin/bash',
  $r_user_present    = 'present',
  $r_username        = 'roblogs',
  $t_user_present    = 'present',
  $t_username        = 'tcblogs',
  $required_packages = [],

# override below in yaml
  $roller_version           = '',
  $roller_revision_number   = '',
  $mysql_connector_version  = '',
  $server_port              = '',
  $connector_port           = '',
  $context_path             = '',
  $docroot                  = '',
  $parent_dir               = '',
  $tomcat_version           = '',
  $tomcat_minor             = '',
  $tomcat_revision_number   = '',

# override below in eyaml

  $jdbc_connection_url = '',
  $jdbc_username       = '',
  $jdbc_password       = '',
  $akismet_apikey      = '',

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# roller specific
  $roller_release           = "${roller_version}.${roller_revision_number}"
  $mysql_connector          = "mysql-connector-java-${mysql_connector_version}.jar"
  $mysql_connector_dest_dir = "${current_dir}/roller/WEB-INF/lib"
  $roller_build             = "roller-release-${roller_release}"
  $r_tarball                = "${roller_build}-standard.tar.gz"
  $download_dir             = '/tmp'
  $downloaded_tarball       = "${download_dir}/${r_tarball}"
  $download_url             = "https://dist.apache.org/repos/dist/release/roller/roller-${roller_version}/v${roller_release}/${r_tarball}"
  $install_dir              = "${parent_dir}/${roller_build}"
  $data_dir                 = "${parent_dir}/roller_data"
  $current_dir              = "${parent_dir}/current"

# tomcat specific
  $tomcat_release           = "${tomcat_version}.${tomcat_minor}.${tomcat_revision_number}"
  $tomcat_build             = "apache-tomcat-${tomcat_release}"
  $t_tarball                = "${tomcat_build}.tar.gz"
  $downloaded_t_tarball     = "${download_dir}/${t_tarball}"
  $download_t_url           = "https://dist.apache.org/repos/dist/release/tomcat/tomcat-${tomcat_version}/v${tomcat_release}/bin/${t_tarball}"
  $tomcat_dir               = "${parent_dir}/${tomcat_build}"

  user {
    $r_username:
      ensure     => $r_user_present,
      name       => $r_username,
      home       => "/home/${r_username}",
      shell      => $shell,
      uid        => $r_uid,
      gid        => $r_groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$r_groupname],
  }

  group {
    $r_groupname:
      ensure => $r_group_present,
      name   => $r_groupname,
      gid    => $r_gid,
  }

  user {
    $t_username:
      ensure     => $t_user_present,
      name       => $t_username,
      home       => "/home/${t_username}",
      shell      => $shell,
      uid        => $t_uid,
      gid        => $t_groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$t_groupname],
  }

  group {
    $t_groupname:
      ensure => $t_group_present,
      name   => $t_groupname,
      gid    => $t_gid,
  }

# download roller
  exec {
    'download-roller':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-roller'],
  }

# extract the download and move it
  exec {
    'extract-roller':
      command => "/bin/tar -xvzf ${r_tarball} && mv ${roller_build} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/NOTICE.txt",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  exec {
    'chown-roller-dirs':
      command => "/bin/chown -R ${r_username}:${r_username} ${install_dir}",
      timeout => 1200,
      require => [User[$r_username],Group[$r_username]],
  }

# download tomcat

  exec {
    'download-tomcat':
      command => "/usr/bin/wget -O ${downloaded_t_tarball} ${download_t_url}",
      creates => $downloaded_t_tarball,
      timeout => 1200,
  }

  file { $downloaded_t_tarball:
    ensure  => file,
    require => Exec['download-tomcat'],
  }

# extract the download and move it
  exec {
    'extract-tomcat':
      command => "/bin/tar -xvzf ${t_tarball} && mv ${tomcat_build} ${tomcat_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${tomcat_dir}/NOTICE",
      timeout => 1200,
      require => [File[$downloaded_t_tarball],File[$parent_dir]],
  }

  exec {
    'chown-tomcat-dirs':
      command => "/bin/chown -R ${t_username}:${t_groupname} ${tomcat_dir}",
      timeout => 1200,
      require => [User[$t_username],Group[$t_groupname]],
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $data_dir:
      ensure => directory,
      owner  => $t_username,
      group  => $r_groupname,
      mode   => '0775';
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$parent_dir];
    "${tomcat_dir}/lib/roller-custom.properties":
      content => template('blogs_asf/roller-custom.properties.erb'),
      mode    => '0644';
  }
}
