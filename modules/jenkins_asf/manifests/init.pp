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
  $parent_dir,
  $server_port                   = '',
  $connector_port                = '',
  $context_path                  = '',

  $required_packages             = ['unzip','wget'],
){

# install required packages:
  package {
    $required_packages:
      ensure => 'present',
  }


http://mirrors.jenkins.io/war-stable/2.32.2/jenkins.war

# jenkins specific
  $download_dir             = '/tmp'
  $downloaded_war           = "${download_dir}/jenkins.war"
  $download_url             = "http://mirrors.jenkins.io/war-stable/${jenkins_version}/jenkins.war"
  $install_dir              = "${parent_dir}/${fisheye_build}"
  $jenkins_home             = "${parent_dir}/jenkins-home"
  $current_dir              = "${parent_dir}/current"

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "/home/${username}",
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

# stuff goes here

file {
    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $jenkins_home:
      ensure  => directory,
      owner   => 'fisheye',
      group   => 'fisheye',
      mode    => '0755',
      require => File[$install_dir];
    $install_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Exec['deploy-war'];
    $current_dir:
      ensure  => link,
      target  => $install_dir,
      owner   => 'root',
      group   => 'root',
      require => File[$install_dir];
  }

