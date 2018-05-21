#/etc/puppet/modules/cwiki_asf/manifests/init.pp

class cwiki_asf (
  $uid                           = 8999,
  $gid                           = 8999,
  $group_present                 = 'present',
  $groupname                     = 'confluence',
  $groups                        = [],
  $service_ensure                = 'running',
  $service_name                  = 'confluence',
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'confluence',

  # override below in yaml
  $confluence_version            = '',
  $conf_build_number             = '',
  $mysql_connector_version       = '',
  $parent_dir,
  $server_port                   = '',
  $connector_port                = '',
  $context_path                  = '',
  $synchrony_path                 = '',
  $synchrony_port                = '',
  $docroot                       = '',
  $server_alias                  = '',
  $heap_min_size                 = '',
  $heap_max_size                 = '',
  # Below setting replaces PermGen, uses native memory for class metadata.
  # If not set resizes according to available native memory.
  $maxmetaspacesize              = '',

  # below are contained in eyaml
  $confluence_license_hash       = '',
  $confluence_license_message    = '',
  $confluence_setup_server_id    = '',
  $hibernate_connection_password = '',
  $hibernate_connection_username = '',
  $hibernate_connection_url      = '',
  $jwt_priv                      = '',
  $jwt_pub                       = '',


  $required_packages             = ['graphviz' , 'graphviz-dev'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# confluence specific
  $mysql_connector          = "mysql-connector-java-${mysql_connector_version}.jar"
  $mysql_connector_dest_dir = '/x1/cwiki/current/confluence/WEB-INF/lib'
  $confluence_build         = "atlassian-confluence-${confluence_version}"
  $tarball                  = "${confluence_build}.tar.gz"
  $download_dir             = '/tmp'
  $downloaded_tarball       = "${download_dir}/${tarball}"
  $download_url             = "http://www.atlassian.com/software/confluence/downloads/binary/${tarball}"
  $install_dir              = "${parent_dir}/${confluence_build}"
  $confluence_home          = "${parent_dir}/confluence-data"
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

# download standalone Confluence
  exec {
    'download-confluence':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-confluence'],
  }

# extract the download and move it
  exec {
    'extract-confluence':
      command => "/bin/tar -xvzf ${tarball} && mv ${confluence_build} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/NOTICE",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  exec {
    'chown-confluence-dirs':
      command => "/bin/chown -R ${username}:${username} ${install_dir}/logs ${install_dir}/temp ${install_dir}/work",
      timeout => 1200,
      require => [User[$username],Group[$username]],
  }

  exec {
    'check_cfg_exists':
      command => '/bin/true',
      onlyif  => "/usr/bin/test -e ${confluence_home}/confluence.cfg.xml",
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $confluence_home:
      ensure  => directory,
      owner   => 'confluence',
      group   => 'confluence',
      mode    => '0755',
      require => File[$install_dir];
    $install_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Exec['extract-confluence'];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$install_dir];
    $intermediates_dir:
      ensure  => directory,
      owner   => 'www-data',
      group   => 'confluence',
      mode    => '0775',
      require => Class['apache'];
    "${install_dir}/confluence/WEB-INF/classes/confluence-init.properties":
      content => template('cwiki_asf/confluence-init.properties.erb'),
      mode    => '0644';
    "${install_dir}/conf/server.xml":
      content => template('cwiki_asf/server.xml.erb'),
      mode    => '0644';
    "${install_dir}/conf/Standalone":
      ensure => directory,
      owner  => 'confluence',
      group  => 'confluence',
      mode   => '0755';
    "${install_dir}/bin/setenv.sh":
      content => template('cwiki_asf/setenv.sh.erb'),
      mode    => '0644';
    # Below mode 0664 required by the confluence app, and will reset it if not matched
    "${confluence_home}/confluence.cfg.xml":
      content => template('cwiki_asf/confluence.cfg.xml.erb'),
      owner   => 'confluence',
      group   => 'confluence',
      mode    => '0664',
      require => Exec['check_cfg_exists'],
      notify  => Service[$service_name];
    "${mysql_connector_dest_dir}/${mysql_connector}":
      ensure => present,
      source => "puppet:///modules/cwiki_asf/${mysql_connector}";
    "/etc/init.d/${service_name}":
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template('cwiki_asf/confluence-init-script.erb');
    "${intermediates_dir}/header.inc":
      ensure => present,
      source => 'puppet:///modules/cwiki_asf/header.inc';
    "${intermediates_dir}/footer.inc":
      ensure => present,
      source => 'puppet:///modules/cwiki_asf/footer.inc';
    "/home/${username}/create-intermediates-index.sh":
      owner   => $username,
      group   => $groupname,
      content => template('cwiki_asf/create-intermediates-index.sh.erb'),
      mode    => '0755';
    "/home/${username}/copy-intermediates.sh":
      owner   => $username,
      group   => $groupname,
      content => template('cwiki_asf/copy-intermediates.sh.erb'),
      mode    => '0755';
    "/home/${username}/remove-intermediates-weekly.sh":
      owner   => $username,
      group   => $groupname,
      content => template('cwiki_asf/remove-intermediates-weekly.sh.erb'),
      mode    => '0755';
    "/home/${username}/cleanup-tomcat-logs.sh":
      owner   => $username,
      group   => $groupname,
      content => template('cwiki_asf/cleanup-tomcat-logs.sh.erb'),
      mode    => '0755';
    '/etc/apache2/solr_id_to_new.map.txt':
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/cwiki_asf/solr_id_to_new.map.txt',
      mode   => '0644';
    '/etc/apache2/solr_name_to_new.map.txt':
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/cwiki_asf/solr_name_to_new.map.txt',
      mode   => '0644';
  }

  service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => Class['apache'],
  }

# cron jobs

  cron {
    'create-intermediates-index':
      user        => $username,
      minute      => '25',
      command     => "/home/${username}/create-intermediates-index.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'copy-intermediates':
      user        => $username,
      minute      => '30',
      command     => "/home/${username}/copy-intermediates.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'remove-intermediates-weekly':
      user        => $username,
      weekday     => 1,
      minute      => 05,
      hour        => 07,
      command     => "/home/${username}/remove-intermediates-weekly.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username];
    'cleanup-tomcat-logs':
      user        => $username,
      minute      => 20,
      hour        => 07,
      command     => "/home/${username}/cleanup-tomcat-logs.sh",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
      require     => User[$username],
}

}
