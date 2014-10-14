#/etc/puppet/modules/dnsclient/manifests/init.pp

class dnsclient (
  $nameservers        = [],
  $packages            = [],
  $pkgprovider         = '',
  $resolvtemplate      = '',
  $searchorder         = '',
) {

  package { $packages: 
    ensure   =>  installed,
  }

  file { 
    '/etc/resolv.conf':
      content => template('dnsclient/resolv.conf.erb');
  }

  # Disable resolveconf since we manage its contents
  package { 'resolvconf':
    ensure => 'purged',
  }
}
