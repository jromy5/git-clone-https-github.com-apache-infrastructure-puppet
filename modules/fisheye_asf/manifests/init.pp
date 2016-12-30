#/etc/puppet/modules/fisheye_asf/manifests/init.pp

class fisheye_asf (
  $uid                           = 8999,
  $gid                           = 8999,
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
  $docroot                       = '',
  $server_alias                  = '',
  $heap_min_size                 = '',
  $heap_max_size                 = '',
  # Below setting replaces PermGen, uses native memory for class metadata.
  # If not set resizes according to available native memory.
  $maxmetaspacesize              = '',

  # below are contained in eyaml
  #$confluence_license_hash       = '',
  #$confluence_license_message    = '',
  #$confluence_setup_server_id    = '',
  $hibernate_connection_password = '',
  $hibernate_connection_username = '',
  $hibernate_connection_url      = '',

  $required_packages             = ['default-jre','unzip','wget'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# fisheye specific
  $mysql_connector          = "mysql-connector-java-${mysql_connector_version}.jar" # lint:ignore:80chars
  #$mysql_connector_dest_dir = '/x1/cwiki/current/confluence/WEB-INF/lib'
  $fisheye_build            = "fisheye-${fisheye_version}"
  $zip                      = "${fisheye_build}.zip"
  $download_dir             = '/tmp'
  $downloaded_zip           = "${download_dir}/${zip}"
  $download_url             = "https://www.atlassian.com/software/fisheye/downloads/binary/${zip}"
  $install_dir              = "${parent_dir}/${fisheye_build}"
  $fisheye_home             = "${parent_dir}/fisheye-data"
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
      command => "/usr/bin/unzip ${zip} && sudo mv fecru-${fisheye_version}/* ${parent_dir}", # lint:ignore:80chars
      cwd     => $download_dir,
      user    => 'root',
      timeout => 1200,
      require => [File[$downloaded_zip],File[$parent_dir]],
  }

  exec {
    'chown-fisheye-dirs':
      command => "/bin/chown -R ${username}:${username} ${install_dir}/logs ${install_dir}/temp ${install_dir}/work", # lint:ignore:80chars
      timeout => 1200,
      require => [User[$username],Group[$username]],
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
  }
  

  service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => false,
      hasrestart => true,
      require    => Class['apache'],
  }
}
