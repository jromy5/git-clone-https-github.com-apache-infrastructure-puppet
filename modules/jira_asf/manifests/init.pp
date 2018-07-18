#/etc/puppet/modules/jira_asf/manifests/init.pp

class jira_asf (
  $uid                            = 9997,
  $gid                            = 9997,
  $group_present                  = 'present',
  $groupname                      = 'jira',
  $groups                         = [],
  $service_ensure                 = 'running',
  $service_name                   = 'jira',
  $shell                          = '/bin/bash',
  $user_present                   = 'present',
  $username                       = 'jira',

  # override below in yaml
  $jira_version                   = '',
  $pgsql_connector_version        = '',
  $parent_dir                     = '/x1/jira',
  $server_port                    = '',
  # Set the connector port to the empty string to disable the connector
  $connector_port_http            = '8080',
  $connector_address_http         = '',
  $connector_port_ajp             = '8009',
  $connector_address_ajp          = '',
  $context_path                   = '',
  $docroot                        = '',
  $server_alias                   = '',
  $jvm_min_size                   = '',
  $jvm_max_size                   = '',
  # Below setting replaces PermGen, uses native memory for class metadata.
  # If not set resizes according to available native memory.
  $maxmetaspacesize               = '',
  $jdbc_user                      = '',
  $jdbc_password                  = '',
  $jdbc_url                       = '',

  # below are contained in eyaml
  $jira_license_hash              = '',
  $jira_license_message           = '',
  $jira_setup_server_id           = '',
  $hibernate_connection_password  = '',
  $hibernate_connection_username  = '',
  $hibernate_connection_url       = '',

  $required_packages              = ['graphviz' , 'graphviz-dev'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# jira specific
  $pgsql_connector          = "postgresql-${pgsql_connector_version}.jar"
  $pgsql_connector_dest_dir = '/x1/jira/current/lib'
  $jira_build               = "atlassian-jira-${jira_version}-standalone"
  $tarball                  = "atlassian-jira-${jira_version}.tar.gz"
  $download_dir             = '/tmp'
  $downloaded_tarball       = "${download_dir}/${tarball}"
  $download_url             = "http://www.atlassian.com/software/jira/downloads/binary/${tarball}"
  $install_dir              = "${parent_dir}/${jira_build}"
  $jira_home                = "${parent_dir}/jira-data"
  $current_dir              = "${parent_dir}/current"
  $dbconfig                 = "${jira_home}/dbconfig.xml"
  $serverxml                = "${current_dir}/conf/server.xml"
  $setenv                   = "${current_dir}/bin/setenv.sh"
  $jira_properties          = "${current_dir}/atlassian-jira/WEB-INF/classes/jira-application.properties"
  $procmailrc               = "/home/${username}/.procmailrc"

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

# download standalone jira
  exec {
    'download-jira':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-jira'],
  }

# extract the download and move it into place
# once extracted, chain the chown to set appropriate owner/group
  exec {
    'extract-jira':
      command => "/bin/tar -xvzf ${tarball} && mv ${jira_build} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/NOTICE",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }
  -> exec {
    'chown-jira-dirs':
      command => "/bin/chown -R ${username}:${username} ${install_dir}",
      timeout => 1200,
      require => [User[$username],Group[$username]],
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $jira_home:
      ensure  => directory,
      owner   => 'jira',
      group   => 'jira',
      mode    => '0755',
      require => File[$install_dir];
    "${jira_home}/logos":
      ensure  => directory,
      owner   => 'jira',
      group   => 'jira',
      mode    => '0755',
      source  => 'puppet:///modules/jira_asf/logos',
      recurse => true,
      require => File[$jira_home];
    $install_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Exec['extract-jira'];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$install_dir];
    $dbconfig:
      content => template ('jira_asf/dbconfig.xml.erb'),
      mode    => '0640',
      owner   => 'jira',
      group   => 'jira',
      require => File[$jira_home];
    $serverxml:
      content => template ('jira_asf/server.xml.erb'),
      mode    => '0640',
      owner   => 'jira',
      group   => 'jira',
      require => File[$jira_home];
    $setenv:
      content => template ('jira_asf/setenv.sh.erb'),
      mode    => '0640',
      owner   => 'jira',
      group   => 'jira',
      require => File[$jira_home];
    $jira_properties:
      content => template ('jira_asf/jira-application.properties.erb'),
      mode    => '0640',
      owner   => 'jira',
      group   => 'jira',
      require => File[$jira_home];
    "${pgsql_connector_dest_dir}/${pgsql_connector}":
      ensure => present,
      source => "puppet:///modules/jira_asf/${pgsql_connector}";
    "${install_dir}/atlassian-jira/WEB-INF/classes/com/atlassian/jira/notification/NotificationRecipient.class":
      ensure  => present,
      source  => "puppet:///modules/jira_asf/${jira_version}/NotificationRecipient.class",
      owner   => 'jira',
      group   => 'jira',
      require => File[$install_dir];
    "${install_dir}/atlassian-jira/WEB-INF/classes/templates/email":
      ensure  => present,
      source  => 'puppet:///modules/jira_asf/email-templates',
      owner   => 'jira',
      group   => 'jira',
      recurse => true,
      require => File[$install_dir];
    $procmailrc:
      content => template ('jira_asf/procmailrc.erb'),
      mode    => '0640',
      owner   => 'jira',
      group   => 'jira',
  }

  logrotate::rule { 'procmail-jira':
    path         => "/home/${username}/Maildir/procmail.log",
    rotate       => 6,
    rotate_every => 'month',
    missingok    => true,
    compress     => true,
  }

  ::systemd::unit_file { 'jira.service':
      source => 'puppet:///modules/jira_asf/jira.service',
  }

}
