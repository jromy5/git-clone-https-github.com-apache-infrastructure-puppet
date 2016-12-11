#/etc/puppet/modules/sonar_asf/manifests/init.pp

class sonar_asf (

  $group_present     = 'present',
  $groupname         = 'sonar',
  $groups            = [],
  $shell             = '/bin/bash',
  $user_present      = 'present',
  $username          = 'sonar',
  $service_ensure    = 'running',
  $service_name      = 'sonar',

  # override below in yaml
  $sonar_version = '',
  $parent_dir,
  $sonar_web_context = '',
  $sonar_web_port = '',

  # override below in eyaml
  $sonar_jdbc_username = '',
  $sonar_jdbc_password = '',
  $sonar_jdbc_url = '',

  $required_packages             = ['tomcat8'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }

# Sonar specific TBD

  class { 'oraclejava::install':
    ensure  => 'latest',
    version => '8',
}->

  group {
    $groupname:
      ensure => $group_present,
      system => true,
  }->

  user {
    $username:
      ensure     => $user_present,
      system     => true,
      name       => $username,
      home       => "/home/${username}",
      shell      => $shell,
      gid        => $groupname,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
  }

  $sonar_build        = "sonarqube-${sonar_version}"
  $tarball            = "${sonar_build}.zip"
  $download_dir       = '/tmp'
  $downloaded_tarball = "${download_dir}/${tarball}"
  $download_url       = "https://sonarsource.bintray.com/Distribution/sonarqube/${tarball}"
  $install_dir        = "${parent_dir}/${sonar_build}"

# download SonarQube
  exec {
    'download-sonarqube':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-sonarqube'],
  }

# extract the download and move it
  exec {
    'extract-sonarqube':
      command => "/usr/bin/unzip ${tarball} -d ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/COPYING",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $install_dir:
      ensure  => directory,
      owner   => 'sonar',
      group   => 'sonar',
      require => Exec['extract-sonarqube'];
    "${install_dir}/conf/sonar.properties":
      content => template('sonar_asf/sonar.properties.erb'),
      owner   => 'sonar',
      group   => 'sonar',
      mode    => '0644',
      require => Exec['extract-sonarqube'],
      notify  => Service[$service_name];
    "${install_dir}/conf/wrapper.conf":
      content => template('sonar_asf/wrapper.conf.erb'),
      owner   => 'sonar',
      group   => 'sonar',
      mode    => '0644',
      require => Exec['extract-sonarqube'],
      notify  => Service[$service_name];
  }

  service {
    $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => false,
      hasrestart => true,
  }

}
