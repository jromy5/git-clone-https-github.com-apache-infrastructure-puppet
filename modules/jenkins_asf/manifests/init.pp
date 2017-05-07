#/etc/puppet/modules/jenkins_asf/manifests/init.pp

class jenkins_asf (
  $group_present                 = 'present',
  $groupname                     = 'jenkins',
  $groups                        = [],
  $service_ensure                = 'stopped',
  $service_name                  = 'jenkins',
  $shell                         = '/bin/bash',
  $user_present                  = 'present',
  $username                      = 'jenkins',

  # override below in yaml
  $jenkins_version               = '',
  $tomcat_version                = '',
  $parent_dir,
  $server_port                   = '',
  $heap_min_size                 = '',
  $heap_max_size                 = '',
  $maxmetaspacesize              = '',

  $required_packages             = ['unzip','wget'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# jenkins specific

  $download_dir     = '/tmp'
  $downloaded_war   = "${download_dir}/jenkins.war"
  $download_url     = "http://mirrors.jenkins.io/war-stable/${jenkins_version}/jenkins.war"
  $install_dir      = "${parent_dir}/${username}"
  $jenkins_home     = "${parent_dir}/${username}/jenkins-home"
  $tools_dir        = "${install_dir}/tools"

# tomcat (9) specific

  $downloaded_tarball = "${download_dir}/${tarball}"
  $t_download_url     = "http://www-us.apache.org/dist/tomcat/tomcat-9/v${tomcat_version}/bin/${tarball}"
  $tomcat_dir         = "${tools_dir}/tomcat"
  $current_dir        = "${tomcat_dir}/current"
  $tomcat_build       = "apache-tomcat-${tomcat_version}"
  $tarball            = "${tomcat_build}.tar.gz"
  $catalina_base      = "${tomcat_dir}/${tomcat_build}"

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "${parent_dir}/${username}",
      shell      => $shell,
      groups     => $groups,
      gid        => $groupname,
      managehome => true,
      require    => Group[$groupname],
      system     => true,
  }

  group {
    $groupname:
      ensure => $group_present,
      system => true,
  }

# download jenkins war

  exec {
    'download-jenkins':
      command => "/usr/bin/wget -O ${downloaded_war} ${download_url}",
      creates => $downloaded_war,
      timeout => 1200,
  }

  file { $downloaded_war:
    ensure  => file,
    require => Exec['download-jenkins'],
}

# Copy the war file into the tomcat webapps dir and deploy.

  exec {
    'deploy-jenkins':
      command => "/bin/cp ${downloaded_war} /var/lib/tomcat8/webapps/ROOT.war && sleep 10",
      cwd     => $install_dir,
      user    => 'root',
      creates => '/var/lib/tomcat8/webapps/ROOT.war',
      timeout => 1200,
      require => [Package['tomcat8'],File[$parent_dir]],
}

file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $jenkins_home:
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      mode    => '0755',
      require => File[$parent_dir];
    $install_dir:
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      require => File[$parent_dir];
    $current_dir:
      ensure  => link,
      target  => $catalina_base,
      owner   => 'root',
      group   => 'root',
      require => File[$catalina_base];
    '/usr/share/tomcat8/bin/setenv.sh':
      content => template('jenkins_asf/setenv.sh.erb'),
      mode    => '0644';
  }
}
