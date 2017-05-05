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

  $required_packages             = ['unzip','wget'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# jenkins specific
  $download_dir             = '/tmp'
  $downloaded_war           = "${download_dir}/jenkins.war"
  $download_url             = "http://mirrors.jenkins.io/war-stable/${jenkins_version}/jenkins.war"
  $tools_dir                = 'tools'
  $install_dir              = "${parent_dir}/${tools_dir}/tomcat/apache-tomcat-${tomcat_version}"
  $jenkins_home             = "${parent_dir}/jenkins-home"
  $current_dir              = "${parent_dir}/${tools_dir}/tomcat/latest"

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "/$(parent_dir}/${username}",
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

# Copy the war file into the tomcat webapps dir.
  exec {
    'cp-jenkins':
      command => "cp ${downloaded_war} ${current_dir}/webapps/ROOT.war",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${current_dir}/webapps/ROOT.war",
      timeout => 1200,
      require => [File[$downloaded_war],File[$current_dir]],
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
      require => File[$tools_dir];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => $username,
      group   => $groupname,
      require => File[$install_dir];
  }
}
