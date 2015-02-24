
 class cwiki_asf (
   $uid = 8999,
   $gid = 8999,
   $group_present = 'present',
   $groupname = 'confluence',
   $groups = [],
   # $service_ensure = 'running',
   # $service_name = 'confluence',
   $shell = '/bin/bash',
   $user_present = 'present',
   $username = 'confluence',
){

# confluence specific

   $confluence_version = '5.0.3'
   $connector_version = '5.1.11'
   $mysql_connector = "mysql-connector-java-${connector_version}.jar"
   $connector_dest_dir = '/x1/cwiki/current/confluence/WEB-INF/lib'
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
  "$parent_dir/current":
    ensure => link,
    target => "${install_dir}",
    owner => 'root',
    group => 'root',
    require => File["${install_dir}"];
  "$install_dir/confluence/WEB-INF/classes/confluence-init.properties":
    content => template('cwiki_asf/confluence-init.properties.erb'),
    mode => '0644';
   # '${connector_dest_dir}/${mysql_connector}':
   #   ensure => present,
   #   source => "puppet:///modules/cwiki_asf/${mysql_connector}",
}

  apache::mod { 'rewrite': }
  # apache::mod { 'proxy': }
  # apache::mod { 'proxy_http': }

  apache::vhost { 'cwiki-vm2':
      vhost_name => '*',
      default_vhost => true,
      servername => 'cwiki-vm2.apache.org',
      port => '80',
      docroot => '/var/www/html',
      serveraliases => ['cwiki-test.apache.org'],
      error_log_file => 'cwiki-test_error.log',
      proxy_pass => [
        { 'path' => '/', 'url' => 'http://127.0.0.1:8888/',
          'reverse_urls' => ['http://127.0.0.1:8888/'] },
      ],
  }

}
