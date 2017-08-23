#/etc/puppet/modules/selfserve_portal/manifests/init.pp

# selfserve class for the self service portal - jira,confluence,mail lists, git repo
class selfserve_portal (

  # Below is in tools yaml

  $cliversion = '',

  # Below contained in eyaml

  $hc_token = '',
  $hc_room  = '',
  $jira_un  = '',
  $jira_pw  = '',

){

  $deploy_dir    = '/var/www/selfserve-portal'
  $install_base  = '/usr/local/etc/'
  $atlassian_cli = "atlassian-cli-$cliversion"

file {
    $deploy_dir:
      ensure  => directory,
      recurse => true,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/selfserve_portal',
      require => Package['apache2'];
    "${install_base}/selfserve/":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    "${install_base}/selfserve/queue":
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755';
    "${install_base}/selfserve/selfserve.yaml":
      content => template('selfserve_portal/selfserve.yaml.erb'),
      owner  => 'root',
      group  => 'root',
      mode    => '0644';

# Required scripts for cronjobs

    "${install_base}/${atlassian_cli}/jira-get-category.sh":
      content => template('selfserve_portal/jira-get-category.sh.erb'),
      owner  => 'root',
      group  => 'root',
      mode    => '0755';
  }

# cronjobs

 cron {
'jira-get-category':
      user        => root,
      minute      => '30',
      command     => "${install_base}/${atlassian_cli}/jira-get-category.sh > /dev/null 2>&1",
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }
}
