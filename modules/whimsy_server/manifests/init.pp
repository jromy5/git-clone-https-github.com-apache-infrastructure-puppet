#/etc/puppet/modules/whimsy_server/manifests/init.pp


class whimsy_server (

  $apmail_keycontent = '',

  $keysdir = hiera('ssh::params::sshd_keysdir')

) {

  ############################################################
  #                       System Packages                    #
  ############################################################

  $packages = [
    libgmp3-dev,
    libldap2-dev,
    libsasl2-dev,
    ruby-dev,
    zlib1g-dev,

    imagemagick,
    pdftk,
  ]

  $gems = [
    bundler,
    rake,
  ]

  package { $packages: ensure => installed } ->

  package { $gems: ensure => installed, provider => gem } ->

  ############################################################
  #               Web Server / Application content           #
  ############################################################

  class { 'rvm::passenger::apache':
    version            => '5.0.23',
    ruby_version       => 'ruby-2.3.0',
    mininstances       => '3',
    maxinstancesperapp => '0',
    maxpoolsize        => '30',
    spawnmethod        => 'smart-lv2',
  } ->

  vcsrepo { '/srv/whimsy':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/apache/whimsy.git',
    before   => Apache::Vhost[whimsy-vm-80]
  } ~>

  exec { 'rake::update':
    command => '/usr/local/bin/rake update',
    cwd => '/srv/whimsy',
    refreshonly => true
  }

  ############################################################
  #                    Subversion Data Source                #
  ############################################################

  file { '/srv/svn':
    ensure => 'directory',
  }

  ############################################################
  #                       Mail Data Source                   #
  ############################################################

  user { apmail:
    ensure   => present,
    uid      => 500,
  }

  file { "$keysdir/apmail.pub":
    content => $apmail_keycontent,
    owner   => apmail,
    mode    => '0640',
  }

  file { '/srv/mbox':
    ensure => directory,
    owner  => apmail,
    group  => apmail,
  }

}
