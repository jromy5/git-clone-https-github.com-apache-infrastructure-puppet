#/etc/puppet/modules/whimsy_server/manifests/init.pp


class whimsy_server (

  $apmail_keycontent = '',

  $keysdir = hiera('ssh::params::sshd_keysdir')

) {

  ############################################################
  #                       System Packages                    #
  ############################################################

  $packages = [
    build-essential,
    libgmp3-dev,
    libldap2-dev,
    libsasl2-dev,
    ruby-dev,
    zlib1g-dev,

    imagemagick,
    nodejs,
    pdftk,
    procmail,
  ]

  $gems = [
    bundler,
    rake,
  ]

  exec { 'Add nodesource sources':
    command => 'curl https://deb.nodesource.com/setup_5.x | bash -',
    creates => '/etc/apt/sources.list.d/nodesource.list',
    path    => ['/usr/bin', '/bin', '/usr/sbin']
  } ->

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
    command     => '/usr/local/bin/rake update',
    cwd         => '/srv/whimsy',
    refreshonly => true
  }

  ############################################################
  #                         Symlink Ruby                     #
  ############################################################

  define whimsy_server::ruby::symlink ($binary = $title, $ruby = '') {
    $version = split($ruby, '-')
    file { "/usr/local/bin/${binary}${version[1]}" :
      ensure  => link,
      target  => "/usr/local/rvm/wrappers/${ruby}/${binary}",
      require => Class[rvm]
    }
  }

  define whimsy_server::rvm::symlink ($ruby = $title) {
    $binaries = [bundle, erb, gem, irb, rackup, rake, rdoc, ri, ruby, testrb]
    whimsy_server::ruby::symlink { $binaries: ruby => $ruby}
  }

  $rubies = keys(hiera_hash('rvm::system_rubies'))
  whimsy_server::rvm::symlink { $rubies: }

  ############################################################
  #                    Subversion Data Source                #
  ############################################################

  user { 'whimsysvn':
    ensure => present,
    home   => '/home/whimsysvn'
  }

  file { '/home/whimsysvn':
    ensure => 'directory',
    owner  => whimsysvn,
    group  => whimsysvn,
  }

  file { '/srv/svn':
    ensure => 'directory',
    owner  => whimsysvn,
    group  => whimsysvn,
  }

  ############################################################
  #                       Mail Data Source                   #
  ############################################################

  user { 'apmail':
    ensure => present,
  }

  file { "${keysdir}/apmail.pub":
    content => $apmail_keycontent,
    owner   => apmail,
    mode    => '0640',
  }

  file { '/srv/mbox':
    ensure => directory,
    owner  => apmail,
    group  => apmail,
  }

  ############################################################
  #                        Mail Delivery                     #
  ############################################################

  file { '/etc/procmailrc':
    content => "MAILDIR=\$DEFAULT\n"
  }

  $mailmap = hiera_hash('whimsy_server::mailmap', {})
  $aliases = keys($mailmap)

  mailalias { $aliases:
    ensure    => present,
    recipient => $apache::user
  } ~>

  exec { 'newaliases' :
    command     => '/usr/bin/newaliases',
    refreshonly => true,
  }

  file { '/var/www/.procmailrc':
    owner   => $apache::user,
    group   => $apache::group,
    content => template('whimsy_server/procmailrc.erb')
  }

  file { '/srv/mail':
    ensure => directory,
    owner  => $apache::user,
    group  => $apache::group,
  }

  file { '/srv/mail/procmail.log':
    ensure => present,
    owner  => $apache::user,
    group  => $apache::group,
  }

  logrotate::rule { 'procmail':
    path         => '/srv/mail/procmail.log',
    rotate       => 6,
    rotate_every => 'month',
    missingok    => true,
    compress     => true,
  }

  ############################################################
  #             Other Working Directories and Files          #
  ############################################################

  file { '/srv/gpg':
    ensure => directory,
    owner  => $apache::user,
    group  => $apache::group,
    mode   => '0700',
  }

  $directories = [
    '/srv/agenda',
    '/srv/secretary',
    '/srv/secretary/tlpreq',
    '/srv/whimsy/www/board/minutes',
    '/srv/whimsy/www/logs',
    '/srv/whimsy/www/public',
  ]

  file { $directories:
    ensure => directory,
    owner  => $apache::user,
    group  => $apache::group,
  }

  file { '/srv/whimsy/www/status/status.json':
    ensure => file,
    owner  => $apache::user,
    group  => $apache::group,
  }

  file { '/srv/whimsy/www/logs/svn-update':
    ensure => file,
    owner  => whimsysvn,
    group  => whimsysvn,
  }

}
