#/etc/puppet/modules/crowd_asf/manifests/init.pp

class crowd_asf (
  $uid                           = 8998,
  $gid                           = 8998,
  $group_present                 = 'present',
  $groupname                     = 'crowd',
  $groups                        = [],
  $service_ensure                = 'running',
  $service_name                  = 'crowd',
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'crowd',

  # override below in yaml
  $crowd_version                 = '',
  $mysql_connector_version       = '',
  $parent_dir,
  $server_port                   = '',
  $connector_port                = '',
  $context_path                  = '',
  $docroot                       = '',
  $server_alias                  = '',
  $heap_min_size                 = '',
  $heap_max_size                 = '',
  # Below setting replaces PermGen, uses native memory for class metadata.
  # If not set resizes according to available native memory.
  $maxmetaspacesize              = '',

  # below are contained in eyaml
  $crowd_license_hash       = '',
  $crowd_license_message    = '',
  $crowd_setup_server_id    = '',
  $hibernate_connection_password = '',
  $hibernate_connection_username = '',
  $hibernate_connection_url      = '',

  $required_packages             = ['graphviz' , 'graphviz-dev'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# crowd specific
  $mysql_connector          = "mysql-connector-java-${mysql_connector_version}.jar" # lint:ignore:80chars
  $mysql_connector_dest_dir = '/x1/crowd/current/crowd/WEB-INF/lib'
  $crowd_build              = "atlassian-crowd-${crowd_version}"
  $tarball                  = "${crowd_build}.tar.gz"
  $download_dir             = '/tmp'
  $downloaded_tarball       = "${download_dir}/${tarball}"
  $download_url             = "http://www.atlassian.com/software/crowd/downloads/binary/${tarball}"
  $install_dir              = "${parent_dir}/${crowd_build}"
  $crowd_home               = "${parent_dir}/crowd-data"
  $current_dir              = "${parent_dir}/current"
  $intermediates_dir        = "${docroot}/intermediates"

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "/home/${username}",
      shell      => $shell,
      uid        => $uid,
      gid        => $groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
  }

  group {
    $groupname:
      ensure => $group_present,
      name   => $groupname,
      gid    => $gid,
  }

# download standalone Crowd
  exec {
    'download-crowd':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-crowd'],
  }

# extract the download and move it
  exec {
    'extract-crowd':
      command => "/bin/tar -xvzf ${tarball} && mv ${crowd_build} ${parent_dir}", # lint:ignore:80chars
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/NOTICE",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  exec {
    'chown-crowd-dirs':
      command => "/bin/chown -R ${username}:${username} ${install_dir}/logs ${install_dir}/temp ${install_dir}/work", # lint:ignore:80chars
      timeout => 1200,
      require => [User[$username],Group[$username]],
  }

  exec {
    'check_cfg_exists':
      command => '/bin/true',
      onlyif  => "/usr/bin/test -e ${crowd_home}/crowd.cfg.xml",
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $crowd_home:
      ensure  => directory,
      owner   => 'crowd',
      group   => 'crowd',
      mode    => '0755',
      require => File[$install_dir];
    $install_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Exec['extract-crowd'];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$install_dir];
    "${install_dir}/crowd/WEB-INF/classes/crowd-init.properties":
      content => template('crowd_asf/crowd-init.properties.erb'),
      mode    => '0644';
    "${install_dir}/conf/server.xml":
      content => template('crowd_asf/server.xml.erb'),
      mode    => '0644';
    "${install_dir}/bin/setenv.sh":
      content => template('crowd_asf/setenv.sh.erb'),
      mode    => '0644';
    "${crowd_home}/crowd.cfg.xml":
      content => template('crowd_asf/crowd.cfg.xml.erb'),
      owner   => 'crowd',
      group   => 'crowd',
      mode    => '0644',
      require => Exec['check_cfg_exists'],
      notify  => Service[$service_name];
    "${mysql_connector_dest_dir}/${mysql_connector}":
      ensure => present,
      source => "puppet:///modules/crowd_asf/${mysql_connector}";
    "/etc/init.d/${service_name}":
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('crowd_asf/crowd-init-script.erb');
    "/home/${username}/cleanup-tomcat-logs.sh":
      owner   => $username,
      group   => $groupname,
      content => template('crowd_asf/cleanup-tomcat-logs.sh.erb'),
      mode    => '0755';
  }

  service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => false,
      hasrestart => true,
      require    => Class['apache'],
  }

# cron jobs

  cron {
    'cleanup-tomcat-logs':
      user        => $username,
      minute      => 20,
      hour        => 07,
      command     => "/home/${username}/cleanup-tomcat-logs.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username],
}

}
