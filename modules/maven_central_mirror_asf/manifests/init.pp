#/etc/puppet/modules/maven_central_mirror_asf/manifests/init.pp

class maven_central_mirror_asf (
  $central_s3_access_key = '',
  $central_s3_secret_key = '',
) {

  include python

  # remove ancient ubuntu package version of awscli

  package { 'awscli':
    ensure  => absent,
  }

  # install current awscli with pip

  python::pip { 'awscli':
    pkgname => 'awscli';
  }

  file {
    '/root/.aws':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
      before => File['/root/.aws/config'];
    '/root/.aws/config':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('maven_central_mirror_asf/aws-config.erb'),
  }

  file {
    '/x1':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      before => File['/x1/central'];
    '/x1/log':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/x1'];
    '/x1/central':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      before => Cron['central_data_sync'];
  }

  cron {
    'central_data_sync':
      environment => 'MAILTO=root@apache.org',
      command     => '/usr/local/bin/aws s3 sync --delete s3://repo-crawler/repos/central/data/ /x1/central/data > /x1/log/central-data-sync-`date +"\%Y-\%m-\%d"`.log',
      hour        => 15,
      minute      => 17;
    'central_updates_sync':
      environment => 'MAILTO=root@apache.org',
      command     => '/usr/local/bin/aws s3 sync --delete s3://repo-crawler/repos/central/updates/ /x1/central/updates > /x1/log/central-updates-sync-`date +"\%Y-\%m-\%d"`.log',
      hour        => 21,
      minute      => 17;
  }

  tidy { '/x1/log':
    age => '1w',
  }
}
