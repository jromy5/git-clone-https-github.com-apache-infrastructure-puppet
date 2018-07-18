#/etc/puppet/modules/blogs_asf/manifests/init.pp

class blogs_asf (
  $required_packages = ['tomcat8'],

# override below in yaml
  $roller_version          = '',
  $roller_revision_number  = '',
  $mysql_connector_version = '',
  $server_port             = '',
  $connector_port          = '',
  $context_path            = '',
  $docroot                 = '',
  $parent_dir              = '',
  $heap_min_size           = '',
  $heap_max_size           = '',
  $maxmetaspacesize        = '',
  $session_timeout         = '30', # 30 minute default for 'remember me'

# override below in eyaml

  $jdbc_connection_url     = '',
  $jdbc_username           = '',
  $jdbc_password           = '',
  $akismet_apikey          = '',

  $roller_bind_passwd      = '',
  $roller_bind_dn          = '',
  $roller_ldap_url         = '',

){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# roller specific
  $roller_release           = "${roller_version}.${roller_revision_number}"
  $mysql_connector          = "mysql-connector-java-${mysql_connector_version}-bin.jar"
  $mysql_connector_dest_dir = '/usr/share/tomcat8/lib'
  $roller_build             = "roller-release-${roller_release}"
  $r_tarball                = "${roller_build}-standard.tar.gz"
  $download_dir             = '/tmp'
  $downloaded_tarball       = "${download_dir}/${r_tarball}"
  $download_url             = "https://dist.apache.org/repos/dist/release/roller/roller-${roller_version}/v${roller_release}/${r_tarball}"
  $install_dir              = "${parent_dir}/${roller_build}"
  $data_dir                 = "${parent_dir}/roller_data"
  $current_dir              = "${parent_dir}/current"

# download roller if the tarball isn't already there

  exec {
    'download-roller':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }
  -> exec {
    'purge-root':
      command => '/bin/rm -rf /var/lib/tomcat8/webapps/ROOT',
      onlyif  => '/usr/bin/test ! -d /var/lib/tomcat8/webapps/ROOT/roller-ui',
  }
  -> exec {
    'extract-roller':
      command => "/bin/tar -xvzf ${r_tarball} && mv ${roller_build} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/NOTICE.txt",
      timeout => 1200,
      require => [Exec['download-roller'],File[$parent_dir]],
  }
  -> exec {
    'deploy-roller':
      command => "/bin/cp ${install_dir}/webapp/roller.war /var/lib/tomcat8/webapps/ROOT.war && sleep 10",
      cwd     => $install_dir,
      user    => 'root',
      creates => '/var/lib/tomcat8/webapps/ROOT.war',
      timeout => 1200,
      require => [Package['tomcat8'],File[$parent_dir]],
  }

# file resources have multiple dependencies to ensure the existence
# of the downloaded source and exploded war file before deploying 
# template artifacts

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      before => Exec['download-roller'];
    $data_dir:
      ensure  => directory,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      mode    => '0775',
      require => [File[$parent_dir],Package['tomcat8']];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'tomcat8',
      group   => 'root',
      require => File[$parent_dir];
    '/usr/share/tomcat8/bin/setenv.sh':
      content => template('blogs_asf/setenv.sh.erb'),
      mode    => '0644';
    '/usr/share/tomcat8/lib/roller-custom.properties':
      content => template('blogs_asf/roller-custom.properties.erb'),
      owner   => 'tomcat8',
      group   => 'root',
      mode    => '0640',
      require => [File[$parent_dir],Package['tomcat8']];
    '/usr/share/tomcat8/lib/planet-custom.properties':
      content => template('blogs_asf/planet-custom.properties.erb'),
      owner   => 'tomcat8',
      group   => 'root',
      mode    => '0640',
      require => [File[$parent_dir],Package['tomcat8']];
    "${mysql_connector_dest_dir}/${mysql_connector}":
      ensure  => present,
      owner   => 'tomcat8',
      group   => 'root',
      mode    => '0644',
      source  => "puppet:///modules/blogs_asf/${mysql_connector}",
      require => [File[$parent_dir],Package['tomcat8']];
    '/usr/share/tomcat8/lib/javax.mail.jar':
      ensure  => present,
      owner   => 'tomcat8',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/blogs_asf/javax.mail.jar',
      require => [File[$parent_dir],Package['tomcat8']];
    '/var/lib/tomcat8/webapps/ROOT/WEB-INF/web.xml':
      ensure  => present,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      content => template('blogs_asf/web.xml.erb'),
      require => [
        File[$parent_dir],
        Package['tomcat8'],
        Exec['deploy-roller'],
      ];
    '/var/lib/tomcat8/webapps/ROOT/themes/asf':
      ensure  => directory,
      recurse => true,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      source  => 'puppet:///modules/blogs_asf/themes/asf',
      require => [
        File[$parent_dir],
        Package['tomcat8'],
        Exec['deploy-roller'],
      ];
    '/var/lib/tomcat8/webapps/ROOT/themes/asffrontpage':
      ensure  => directory,
      recurse => true,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      source  => 'puppet:///modules/blogs_asf/themes/asffrontpage',
      require => [
        File[$parent_dir],
        Package['tomcat8'],
        Exec['deploy-roller'],
      ];
    '/var/lib/tomcat8/webapps/ROOT/images':
      ensure  => directory,
      recurse => true,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      source  => 'puppet:///modules/blogs_asf/images',
      require => [Exec['deploy-roller']];
    '/var/lib/tomcat8/webapps/ROOT/WEB-INF/security.xml':
      ensure  => present,
      owner   => 'tomcat8',
      group   => 'tomcat8',
      content => template('blogs_asf/security.xml.erb'),
      require => [
        File[$parent_dir],
        Package['tomcat8'],
        Exec['deploy-roller'],
      ];
  }
}
