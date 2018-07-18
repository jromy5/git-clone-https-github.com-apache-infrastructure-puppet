#/etc/puppet/modules/whimsy_server/manifests/init.pp


class whimsy_server (

  $ruby_version = hiera('ruby_version'),

) {

  file { '/x1':
    ensure => directory,
  }

  file { '/x1/srv':
    ensure => directory,
  }

  file { '/srv':
    ensure => link,
    force  => true,
    target => '/x1/srv'
  }

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

    gnupg2,
  ]

  exec { 'Add nodesource sources':
    command => 'curl https://deb.nodesource.com/setup_8.x | bash -',
    creates => '/etc/apt/sources.list.d/nodesource.list',
    path    => ['/usr/bin', '/bin', '/usr/sbin']
  }
  -> package { $packages: ensure => installed }
  -> class { 'rvm::passenger::apache':
    version            => '5.1.12',
    ruby_version       => "ruby-${ruby_version}",
    mininstances       => '3',
    maxinstancesperapp => '0',
    maxpoolsize        => '30',
    spawnmethod        => 'smart-lv2',
  }
  -> vcsrepo { '/x1/srv/whimsy':
    ensure   => latest,
    provider => git,
    source   => 'https://gitbox.apache.org/repos/asf/whimsy.git',
    before   => Apache::Vhost[whimsy-vm-80]
  }
  ~> exec { 'rake::update':
    command     => "/usr/local/bin/rake${ruby_version} update",
    cwd         => '/x1/srv/whimsy',
    refreshonly => true,
    require     => [
      Rvm_gem['bundler'],
      Rvm_gem['rake'],
    ]
  }

  ############################################################
  #                         Symlink Ruby                     #
  ############################################################

  # define ruby symlinking
  define whimsy_server::ruby::symlink ($binary = $title, $ruby = '') {
    $version = split($ruby, '-')
    file { "/usr/local/bin/${binary}${version[1]}" :
      ensure  => link,
      target  => "/usr/local/rvm/wrappers/${ruby}/${binary}",
      require => Class[rvm]
    }
  }

  # define rvm symlinking
  define whimsy_server::rvm::symlink ($ruby = $title) {
    $binaries = [bundle, erb, gem, irb, rackup, rake, rdoc, ri, ruby, testrb]
    whimsy_server::ruby::symlink { $binaries: ruby => $ruby}
  }

  $rubies = keys(hiera_hash('rvm::system_rubies'))
  whimsy_server::rvm::symlink { $rubies: }

  ############################################################
  #                 Subversion/Git Data Sources              #
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

  file { '/x1/srv/svn':
    ensure => 'directory',
    owner  => whimsysvn,
    group  => whimsysvn,
  }

  file { '/x1/srv/git':
    ensure => 'directory',
    owner  => whimsysvn,
    group  => whimsysvn,
  }

  ############################################################
  #                      Whimsy pubsub                       #
  ############################################################

  file { '/etc/init/whimsy-pubsub.conf' :
    source => 'puppet:///modules/whimsy_server/whimsy-pubsub.conf'
  }
  -> file { '/etc/systemd/system/whimsy-pubsub.service' :
    source => 'puppet:///modules/whimsy_server/whimsy-pubsub.service'
  }
  -> service { 'whimsy-pubsub':
    ensure  => running,
    require => Vcsrepo['/x1/srv/whimsy']
  }

  ############################################################
  #              Board Agenda WebSocket Server               #
  ############################################################

  file { '/etc/init/board-agenda-websocket.conf' :
    source => 'puppet:///modules/whimsy_server/board-agenda-websocket.conf'
  }
  -> file { '/etc/systemd/system/board-agenda-websocket.service' :
    source => 'puppet:///modules/whimsy_server/board-agenda-websocket.service'
  }
  -> service { 'board-agenda-websocket':
    ensure  => running,
    require => Vcsrepo['/x1/srv/whimsy']
  }

  ############################################################
  #             Other Working Directories and Files          #
  ############################################################

  file { '/x1/srv/gpg':
    ensure => directory,
    owner  => $apache::user,
    group  => $apache::group,
    mode   => '0700',
  }

  file { '/x1/srv/subscriptions':
    ensure => directory,
    owner  => 'apmail',
    group  => 'apmail',
  }

  $directories = [
    '/x1/srv/agenda',
    '/x1/srv/cache',
    '/x1/srv/secretary',
    '/x1/srv/secretary/tlpreq',
    '/x1/srv/whimsy/www/board/minutes',
    '/x1/srv/whimsy/www/logs',
    '/x1/srv/whimsy/www/public',
  ]

  file { $directories:
    ensure  => directory,
    owner   => $apache::user,
    group   => $apache::group,
    require => Vcsrepo['/x1/srv/whimsy']
  }

  file { '/x1/srv/whimsy/www/members/log':
    ensure => link,
    target => '/var/log/apache2'
  }

  file { '/var/log/apache2':
    ensure => directory,
    mode   => '0755',
  }

  file { '/x1/srv/whimsy/www/status/status.json':
    ensure => file,
    owner  => $apache::user,
    group  => $apache::group,
  }

  file { '/x1/srv/whimsy/www/logs/svn-update':
    ensure => file,
    owner  => whimsysvn,
    group  => whimsysvn,
  }

  file { '/x1/srv/whimsy/www/logs/git-pull':
    ensure => file,
    owner  => whimsysvn,
    group  => whimsysvn,
  }

}
