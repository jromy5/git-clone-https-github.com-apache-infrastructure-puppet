
 class cwiki_asf (
   $uid = 8999,
   $gid = 8999,
   $group_present = 'present',
   $groupname = 'confluence',
   $groups = [],
   $service_ensure = 'stopped',
   $service_name = 'confluence',
   $shell = '/bin/bash',
   $user_present = 'present',
   $username = 'confluence',
   # below are contained in eyaml
   $confluence_license_hash = '',
   $confluence_license_message = '',
   $confluence_setup_server_id = '',
   $hibernate_connection_password = '',
   $hibernate_connection_username = '',
   $hibernate_connection_url = '',
){

# confluence specific

   $confluence_version = '5.0.3'
   $mysql_connector_version = '5.1.11'
   $mysql_connector = "mysql-connector-java-${mysql_connector_version}.jar"
   $mysql_connector_dest_dir = '/x1/cwiki/current/confluence/WEB-INF/lib'
   $confluence_build = "atlassian-confluence-${confluence_version}"
   $tarball = "${confluence_build}.tar.gz"
   $download_dir = '/tmp'
   $downloaded_tarball = "${download_dir}/${tarball}"
   $download_url = "http://www.atlassian.com/software/confluence/downloads/binary/${tarball}"
   $parent_dir = "/x1/cwiki"
   $install_dir = "${parent_dir}/${confluence_build}"
   $confluence_home = "${parent_dir}/confluence-data"
   $server_port = '8008'
   $connector_port = '8888'
   $context_path = ''
   $current_dir = "${parent_dir}/current"

    user { "${username}":
         name => "${username}",
         ensure => "${user_present}",
         home => "/home/${username}",
         shell => "${shell}",
         uid => "${uid}",
         gid => "${groupname}",
         groups => $groups,
         managehome => true,
         require => Group["${groupname}"],
    }

    group { "${groupname}":
          name => "${groupname}",
          ensure => "${group_present}",
          gid => "${gid}",
    }

# download standalone Confluence

    exec { "download-confluence":
           command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
           creates => $downloaded_tarball,
           timeout => 1200,
    }
 
      file { $downloaded_tarball:
           require => Exec["download-confluence"],
           ensure => file,
    }

# extract the download and move it

    exec { "extract-confluence":
           command => "/bin/tar -xvzf ${tarball} && mv ${confluence_build} ${parent_dir}",
           cwd => $download_dir,
           user => 'root',
           creates => "${install_dir}/NOTICE",
           timeout => 1200,
           require => [File[$downloaded_tarball],File[$parent_dir]],
}

    exec { "chown-confluence-dirs":
           command => "/bin/chown -R ${username}:${username} ${install_dir}/logs ${install_dir}/temp ${install_dir}/work",
           timeout => 1200,
           require => [User["${username}"],Group["${username}"]],
}

   exec { "check_cfg_exists":
          command => '/bin/true',
          onlyif => "/usr/bin/test -e ${confluence_home}/confluence.cfg.xml",
}

 file { 
  $parent_dir:
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755';
  $confluence_home:
    ensure => directory,
    owner => 'confluence',
    group => 'confluence',
    mode => '0755',
    require => File["${install_dir}"];
  $install_dir:
    ensure => directory,
    owner => 'root',
    group => 'root',
    require => Exec["extract-confluence"];
  $current_dir:
    ensure => link,
    target => "${install_dir}",
    owner => 'root',
    group => 'root',
    require => File["${install_dir}"];
  "$install_dir/confluence/WEB-INF/classes/confluence-init.properties":
    content => template('cwiki_asf/confluence-init.properties.erb'),
    mode => '0644';
  "$install_dir/conf/server.xml":
    content => template('cwiki_asf/server.xml.erb'),
    mode => '0644';
  "$confluence_home/confluence.cfg.xml":
    content => template('cwiki_asf/confluence.cfg.xml.erb'),
    owner => 'confluence',
    group => 'confluence',
    mode => '0644',
    require => Exec["check_cfg_exists"],
    notify => Service["${service_name}"];
  "${mysql_connector_dest_dir}/${mysql_connector}":
    ensure => present,
    source => "puppet:///modules/cwiki_asf/${mysql_connector}";
  "/etc/init.d/${service_name}":
    mode => 0755,
    owner => 'root',
    group => 'root',
    content => template('cwiki_asf/confluence-init-script.erb');
}

  apache::mod { 'rewrite': }
  # apache::mod { 'proxy': }
  # apache::mod { 'proxy_http': }

  apache::vhost { 'cwiki-vm3':
      vhost_name => '*',
      default_vhost => true,
      servername => 'cwiki-vm3.apache.org',
      port => '80',
      docroot => '/var/www/html',
      serveraliases => ['cwiki-test.apache.org'],
      error_log_file => 'cwiki-test_error.log',
      proxy_pass => [
        { 'path' => '/', 'url' => 'http://127.0.0.1:8888/',
          'reverse_urls' => ['http://127.0.0.1:8888/'] },
      ],
  }

  service { "${service_name}":
      ensure => $service_ensure,
      enable => true,
      hasstatus => false,
      hasrestart => true,
      require => Class['apache'],
  }

}
