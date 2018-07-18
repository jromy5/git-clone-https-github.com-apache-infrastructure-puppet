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

  # Disable resolveconf since we manage its contents
  # immediately notify our file block to recreate resolv.conf
  # from erb template so we don't run without a resolv.conf
  # due to puppet resource ordering

  package { 'resolvconf':
    ensure => 'purged',
  }

  ~> file {
    '/etc/resolv.conf':
      content => template('dnsclient/resolv.conf.erb');
    $dhclienthooksfile:
      content => "#!/bin/sh\n make_resolv_conf(){ \n : \n }",
      mode    => '0750';
  }

}
