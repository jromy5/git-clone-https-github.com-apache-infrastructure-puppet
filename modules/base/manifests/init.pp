#/usr/local/etc/puppet/modules/base/manifests/init.pp

class base (
  $basepackages   = [],
  $gempackages    = [],
  $purgedpackages = [],
  $pkgprovider    = '',
) {

  $packages = hiera_array('base::basepackages', [])

  package { $packages:
    ensure =>  installed,
  }

  package { $gempackages:
    ensure   => installed,
    provider => 'gem',
  }

  package { $purgedpackages:
    ensure => purged,
  }

  $hosts = hiera_hash('base::hosts', {})
  create_resources(host, $hosts)

  $perl_module = hiera_hash('perl::module', {})
  create_resources(perl::module, $perl_module)

  $logrotate_rule = hiera_hash('logrotate::rule', {})
  create_resources(logrotate::rule, $logrotate_rule)

  $crons = hiera_hash('cron', {})
  create_resources(cron, $crons)

  $rsync_modules = hiera_hash('rsync::server::module', {})
  create_resources(rsync::server::module, $rsync_modules)

  $stunnels = hiera_hash('stunnel::tun', {})
  create_resources(stunnel::tun, $stunnels)

  $awscli_profile = hiera_hash('awscli::profile', {})
  create_resources(awscli::profile, $awscli_profile)

  class { "base::install::${::asfosname}::${::asfosrelease}":
  }
}
