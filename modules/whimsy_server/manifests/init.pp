#/etc/puppet/modules/whimsy_server/manifests/init.pp


class whimsy_server (

) {

  $packages = [
    'libsasl2-dev',
    'libldap2-dev',
    'ruby-dev',
    'zlib1g-dev',
    'libgmp3-dev',
  ]

  $gems = [
    'bundler',
  ]

  package { $packages: ensure => installed}
  package { $gems: ensure => installed, provider => gem}

  class { 'rvm::passenger::apache':
    version            => '5.0.23',
    ruby_version       => 'ruby-2.3.0',
    mininstances       => '3',
    maxinstancesperapp => '0',
    maxpoolsize        => '30',
    spawnmethod        => 'smart-lv2',
  }

  vcsrepo { '/srv/whimsy':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/apache/whimsy.git'
  }

}
