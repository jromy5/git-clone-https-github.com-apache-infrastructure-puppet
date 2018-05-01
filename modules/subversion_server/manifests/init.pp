#/etc/puppet/modules/subversion_server/manifests/init.pp

class subversion_server (

  $asf_committers_authz = '',
  $packages             = ['python-ldap'],
  $s3_access_key        = '',
  $s3_gpg_passphrase    = '',
  $s3_secret_key        = '',
  $svn_master_hostname  = 'svn-master.apache.org',

) {

  require customfact
  require ldapclient
  require pam

  # packages needed 
  package { $packages:
    ensure => installed,
  }

  user { 'www-data':
    home       => '/home/www-data',
    managehome => true,
    before     => Package['apache2'],
  }

  # File block to deploy folders, scripts etc
  file {
    '/x1':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/etc/viewvc/viewvc.conf':
      ensure => present,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775',
      source => 'puppet:///modules/subversion_server/viewvc/conf/viewvc.conf';
    '/etc/viewvc/templates':
      ensure  => directory,
      recurse => true,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      source  => 'puppet:///modules/subversion_server/viewvc/templates';
    '/x1/svn/hooks':
      ensure  => directory,
      recurse => true,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      source  => 'puppet:///modules/subversion_server/hooks';
    '/x1/svn/scripts':
      ensure  => directory,
      recurse => true,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      source  => 'puppet:///modules/subversion_server/scripts';
    '/x1/svn/authorization':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/authorization/templates':
      ensure  => directory,
      recurse => true,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      source  => 'puppet:///modules/subversion_server/authorization',
      require => File['/x1/svn/authorization'];
    [ '/var/log/svnmailer', '/var/log/svnmailer/errors']:
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/dump':
      ensure => directory,
      mode   => '0775';
    '/dump-tmp':
      ensure => directory,
      mode   => '0775';
    '/x1/svn/dump-tmp':
      ensure => directory,
      mode   => '0775';
    '/usr/local/bin/svn_create_dump.sh':
      source => 'puppet:///modules/subversion_server/svn_create_dump.sh',
      mode   => '0775';
    '/usr/local/bin/svn_create_index.sh':
      source => 'puppet:///modules/subversion_server/svn_create_index.sh',
      mode   => '0775';
    '/usr/local/bin/svn_sync_to_aws_s3.sh':
      source => 'puppet:///modules/subversion_server/svn_sync_to_aws_s3.sh',
      mode   => '0775';
    '/x1/www':
      ensure  => directory,
      recurse => true,
      source  => 'puppet:///modules/subversion_server/www',
      mode    => '0775',
      owner   => 'www-data',
      group   => 'svnadmins';
    '/x1/www/viewvc':
      ensure => link,
      target => '/usr/lib/viewvc/cgi-bin/viewvc.cgi',
      owner  => 'www-data',
      group  => 'svnadmins';
  }

  # file block for repo skeletons
  file {
    '/x1/svn/repos':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn'];
    '/x1/svn/repos/asf':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/asf/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/dist':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/dist/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/infra':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/infra/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/private':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/private/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/tck':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/tck/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/test':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/test/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
    '/x1/svn/repos/bigdata':
      ensure  => directory,
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/repos'];
    '/x1/svn/repos/bigdata/hooks':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins',
      mode   => '0775';
  }

  # file block for templated hooks
  file {
    '/x1/svn/hooks/post-commit-dist':
      content => template('subversion_server/post-commit-dist.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-commit-tck':
      content => template('subversion_server/post-commit-tck.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-commit-infra':
      content => template('subversion_server/post-commit-infra.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-commit-private':
      content => template('subversion_server/post-commit-private.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/pre-commit-bigdata':
      content => template('subversion_server/pre-commit-bigdata.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-commit-bigdata':
      content => template('subversion_server/post-commit-bigdata.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-commit':
      content => template('subversion_server/post-commit.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-revprop-change':
      content => template('subversion_server/post-revprop-change.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/pre-revprop-change':
      content => template('subversion_server/pre-revprop-change.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'];
    '/x1/svn/hooks/post-revprop-change-dist':
      content => template('subversion_server/post-revprop-change-dist.erb'),
      owner   => 'www-data',
      group   => 'svnadmins',
      mode    => '0775',
      require => File['/x1/svn/hooks'],
  }

  # File block to setup the plethora of symlinks needed
  # Generic Files
  file {
    '/x1/svn/asf-mailer.conf':
      ensure  => link,
      target  => '/x1/svn/authorization/templates/asf-mailer.conf',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/asf-mailer-dist.conf':
      ensure  => link,
      target  => '/x1/svn/authorization/templates/asf-mailer-dist.conf',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/asf-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/asf-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/pit-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/pit-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    '/x1/svn/asf-dist-authorization':
      ensure  => link,
      target  => '/x1/svn/authorization/asf-dist-authorization',
      owner   => 'www-data',
      group   => 'svnadmins',
      require => File['/x1/svn/authorization'];
    }


    # /repos/asf specific files
    file {
    '/x1/svn/repos/asf/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/asf/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/hot-backups.d':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins';
    '/var/log/svnsynclog':
      ensure => file,
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    # /repos/dist specific files
    file {
    '/x1/svn/repos/dist/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit-dist',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock-dist',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change-dist',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/dist/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock-dist',
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    # /repos/infra specific files
  file {
    '/x1/svn/repos/infra/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit-infra',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit-infra',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/infra/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/infra-backups.d':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins';
    '/var/log/svninfrasynclog':
      ensure => file,
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    # /repos/private specific files
    file {
    '/x1/svn/repos/private/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit-private',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit-private',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/private/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/private-backups.d':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins';
    '/var/log/svnprivatesynclog':
      ensure => file,
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    # /repos/tck specific files
    file {
    '/x1/svn/repos/tck/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit-tck',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit-tck',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/tck/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/tck-backups.d':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins';
    '/var/log/svntcksynclog':
      ensure => file,
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    # /repos/bigdata specific files
    file {
    '/x1/svn/repos/bigdata/hooks/pre-commit':
      ensure => link,
      target => '/x1/svn/hooks/pre-commit-bigdata',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/start-commit':
      ensure => link,
      target => '/x1/svn/hooks/start-commit',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/post-commit':
      ensure => link,
      target => '/x1/svn/hooks/post-commit-bigdata',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/pre-lock':
      ensure => link,
      target => '/x1/svn/hooks/pre-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/post-lock':
      ensure => link,
      target => '/x1/svn/hooks/post-lock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/post-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/post-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/pre-revprop-change':
      ensure => link,
      target => '/x1/svn/hooks/pre-revprop-change',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/pre-unlock':
      ensure => link,
      target => '/x1/svn/hooks/pre-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/repos/bigdata/hooks/post-unlock':
      ensure => link,
      target => '/x1/svn/hooks/post-unlock',
      owner  => 'www-data',
      group  => 'svnadmins';
    '/x1/svn/bigdata-backups.d':
      ensure => directory,
      owner  => 'www-data',
      group  => 'svnadmins';
    '/var/log/svnbigdatasynclog':
      ensure => file,
      owner  => 'www-data',
      group  => 'svnadmins';
    }

    file { '/x1/svn/asf-committers':
      owner   => 'root',
      group   => 'www-data',
      content => $asf_committers_authz,
      mode    => '0640',
    }

  cron {
    'authz-rebuild-new':
      minute  => '*/3',
      hour    => '*',
      user    => 'www-data',
      command => '/x1/svn/scripts/authorization/gen.py';
    'generate-dist-auth':
      minute  => '15',
      hour    => '*',
      user    => 'www-data',
      command => 'cd /x1/svn/authorization/templates ; ./generate-dist-authorization > asf-dist-authorization.t && mv asf-dist-authorization.t ../asf-dist-authorization'; # lint:ignore:140chars
    'svn-create-dump':
      monthday => '1',
      minute   => '15',
      hour     => '1',
      user     => 'root',
      require  => File['/usr/local/bin/svn_create_dump.sh'],
      command  => '/usr/local/bin/svn_create_dump.sh';
    'svn-create-index':
      monthday => '1',
      minute   => '15',
      hour     => '2',
      user     => 'root',
      require  => File['/usr/local/bin/svn_create_index.sh'],
      command  => '/usr/local/bin/svn_create_index.sh';
    'svn_syncdump_to_aws_s3':
      monthday => '1',
      minute   => '30',
      hour     => '2',
      user     => 'root',
      require  => File['/usr/local/bin/svn_sync_to_aws_s3.sh'],
      command  => '/usr/local/bin/svn_sync_to_aws_s3.sh';
  }

  # s3 backup
  file {
    '/root/.s3cfg':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('subversion_server/s3cfg.erb'),
  }

  host { 'svn-master.apache.org':
    ip           => $::ipaddress,
    host_aliases => $::fqdn,
  }

  # Gunicorn for viewvc
  # Run this command unless gunicorn is already running.
  # -w 10 == 10 workers, we can up that if need be.
  exec { '/usr/local/bin/gunicorn -w 8 -b 127.0.0.1:8080 -D viewvc-wsgi:application':
    path   => '/usr/bin:/usr/sbin:/bin',
    user   => 'www-data',
    group  => 'www-data',
    cwd    =>  '/usr/lib/viewvc/cgi-bin/',
    unless => '/bin/ps ax | /bin/grep -q [g]unicorn',
  }

}
