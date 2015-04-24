#/etc/puppet/modules/dnsclient/manifests/init.pp

class dnsclient (
  $nameservers       = [],
  $packages          = [],
  $pkgprovider       = '',
  $resolvtemplate    = '',
  $searchorder       = '',
  $dhclienthooksfile = '',
) {

  package { $packages:
    ensure => installed,
  }

  file {
    '/etc/resolv.conf':
      content => template('dnsclient/resolv.conf.erb');
    $dhclienthooksfile:
      content => "#!/bin/sh\n make_resolv_conf(){ \n : \n }",
      mode    => '0750';
  }

  # Disable resolveconf since we manage its contents
  package { 'resolvconf':
    ensure => 'purged',
  }
}
