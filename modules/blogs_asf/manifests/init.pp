#/etc/puppet/modules/blogs_asf/manifests/init.pp

class blogs_asf (
  $required_packages = ['tomcat8'],

# override below in yaml
  $roller_version           = '',
  $roller_revision_number   = '',
  $mysql_connector_version  = '',
  $server_port              = '',
  $connector_port           = '',
  $context_path             = '',
  $docroot                  = '',
  $parent_dir               = '',

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

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $data_dir:
      ensure  => directory,
      owner   => tomcat8,
      group   => tomcat8,
      mode    => '0775',
      require => [File[$parent_dir],Package['tomcat8']];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$parent_dir];
    '/usr/share/tomcat8/lib/roller-custom.properties':
      content => template('blogs_asf/roller-custom.properties.erb'),
      mode    => '0644';
  }
}
