
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
   $context_path = '/confluence'
   $current_dir = "${parent_dir}/current"
   $docroot = '/var/www'
   $intermediates_dir = "${docroot}/intermediates"

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
  $intermediates_dir:
    ensure => directory,
    owner => 'www-data',
    group => 'confluence',
    mode => '0775',
    require => Class['apache'];
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
  "${intermediates_dir}/header.inc":
    ensure => present,
    source => "puppet:///modules/cwiki_asf/header.inc";
  "${intermediates_dir}/footer.inc":
    ensure => present,
    source => "puppet:///modules/cwiki_asf/footer.inc";
  "/home/${username}/create-intermediates-index.sh":
    owner => "${username}",
    group => "${groupname}",
    content => template('cwiki_asf/create-intermediates-index.sh.erb'),
    mode => '0755';
  "/home/${username}/copy-intermediate-html.sh":
    owner => "${username}",
    group => "${groupname}",
    content => template('cwiki_asf/copy-intermediate-html.sh.erb'),
    mode => '0755';
  "/home/${username}/remove-intermediates-daily.sh":
    owner => "${username}",
    group => "${groupname}",
    content => template('cwiki_asf/remove-intermediates-daily.sh.erb'),
    mode => '0755';
  "/home/${username}/cleanup-tomcat-logs.sh":
    owner => "${username}",
    group => "${groupname}",
    content => template('cwiki_asf/cleanup-tomcat-logs.sh.erb'),
    mode => '0755';
}

  # apache::mod { 'rewrite': }
  # apache::mod { 'proxy': }
  # apache::mod { 'proxy_http': }

  apache::vhost { 'cwiki-vm3':
      vhost_name => '*',
      default_vhost => true,
      servername => 'cwiki-vm3.apache.org',
      port => '443',
      docroot => "${docroot}",
      serveraliases => ['cwiki-test.apache.org'],
      error_log_file => 'cwiki-test_error.log',
      ssl => true,
      ssl_cert => '/etc/ssl/certs/cwiki.apache.org.crt',
      ssl_chain => '/etc/ssl/certs/cwiki.apache.org.chain',
      ssl_key => '/etc/ssl/private/cwiki.apache.org.key',
      rewrites => [
        {
          comment      => 'redirect from / to /confluence for most.',
          rewrite_cond => ['$1 !(confluence|intermediates)'],
          rewrite_rule => ['^/(.*) http://cwiki-test.apache.org/confluence/display/$1 [R=301,L]'],
        },
      ],
      proxy_pass => [
        { 'path' => '/confluence', 'url' => 'http://127.0.0.1:8888/confluence',
          'reverse_urls' => ['http://127.0.0.1:8888/confluence'] },
      ],
      #    no_proxy_uris => ['/intermediates'],
      custom_fragment => 'ProxyPass /intermediates !'
  }

  service { "${service_name}":
      ensure => $service_ensure,
      enable => true,
      hasstatus => false,
      hasrestart => true,
      require => Class['apache'],
  }

# cron jobs

  cron { 'create-intermediates-index':
    user => "${username}",
    minute => '*/30',
    command => "/home/${username}/create-intermediates-index.sh",
    environment => 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
    SHELL=/bin/sh',
    require => User["${username}"],
}
  cron { 'copy-intermediate-html':
    user => "${username}",
    minute => '*/10',
    command => "/home/${username}/copy-intermediate-html.sh",
    environment => 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
    SHELL=/bin/sh',
    require => User["${username}"],
}
  cron { 'remove-intermediates-daily':
    user => "${username}",
    minute => 05,
    hour => 07,
    command => "/home/${username}/remove-intermediates-daily.sh",
    environment => 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
    SHELL=/bin/sh',
    require => User["${username}"],
}
  cron { 'cleanup-tomcat-logs':
    user => "${username}",
    minute => 20,
    hour => 07,
    command => "/home/${username}/cleanup-tomcat-logs.sh",
    environment => 'PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
    SHELL=/bin/sh',
    require => User["${username}"],
}

}
