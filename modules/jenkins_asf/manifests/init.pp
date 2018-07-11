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
  $server_alias                  = '',
  $server_port                   = '',
  $connector_port                = '',
  $max_threads                   = '',
  $heap_min_size                 = '',
  $heap_max_size                 = '',
  $maxmetaspacesize              = '',
  $tomcat_caching_allowed        = '',
  $tomcat_caching_max_size       = '',

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

  $tomcat_dir         = "${tools_dir}/tomcat"
  $current_dir        = "${tomcat_dir}/current"
  $tomcat_build       = "apache-tomcat-${tomcat_version}"
  $tarball            = "${tomcat_build}.tar.gz"
  $catalina_base      = "${tomcat_dir}/${tomcat_build}"

  $downloaded_tarball = "${download_dir}/${tarball}"
  $t_download_url     = "https://www.apache.org/dist/tomcat/tomcat-9/v${tomcat_version}/bin/${tarball}"

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

# download and extract Tomcat

# download

  exec {
    'download-tomcat':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${t_download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-tomcat'],
  }

# extract into place

  exec {
    'extract-tomcat':
      command => "/bin/tar -xvzf ${tarball} && mv ${tomcat_build} ${tomcat_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${catalina_base}/NOTICE",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$tools_dir]],
  }

  exec {
    'chown-tomcat-dirs':
      command => "/bin/chown -R ${username}:${username} ${catalina_base}/logs ${catalina_base}/temp ${catalina_base}/work ${catalina_base}/conf ${catalina_base}/webapps", # lint:ignore:140chars
      timeout => 1200,
      require => [User[$username],Group[$username],Exec['extract-tomcat']],
}

# make sh scripts executable by jenkins user.

  exec {
    'chgrp-tomcat-files':
      command => "/bin/chgrp ${username} ${catalina_base}/bin ${catalina_base}/bin/*.sh ${catalina_base}/bin/*.jar ${catalina_base}/lib ${catalina_base}/lib/*.jar", # lint:ignore:140chars
      timeout => 1200,
      require => [User[$username],Group[$username],Exec['extract-tomcat']],
}

# Copy the jenkins war file into the tomcat webapps dir and deploy.

  exec {
    'deploy-jenkins':
      command => "/bin/cp ${downloaded_war} ${catalina_base}/webapps/ROOT.war && sleep 10",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${catalina_base}/webapps/ROOT.war",
      timeout => 1200,
      require => [File[$parent_dir],File[$downloaded_war],File[$tomcat_dir]],
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
      require => Exec['extract-tomcat'];
    "${current_dir}/bin/setenv.sh":
      content => template('jenkins_asf/setenv.sh.erb'),
      mode    => '0644';
    $tools_dir:
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      require => File[$install_dir];
    $tomcat_dir:
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      require => File[$tools_dir];
    "${current_dir}/conf/server.xml":
      content => template('jenkins_asf/server.xml.erb'),
      mode    => '0644';
    "${current_dir}/conf/context.xml":
      content => template('jenkins_asf/context.xml.erb'),
      mode    => '0644';
  }


  ::systemd::unit_file { 'jenkins.service':
    content => template('jenkins_asf/jenkins.service.erb'),
  }

}
