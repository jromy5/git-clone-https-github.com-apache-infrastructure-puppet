#/etc/puppet/modules/spamassassin/manifests/spamc/install/ubuntu/1404.pp

class spamassassin::spamc::install::ubuntu::1404 (

  $spamd_peers           = '',
  $haproxy_maxconns      = '',
  $haproxy_port          = '',
  $haproxy_mode          = 'tcp',
  $haproxy_statsuser     = '',
  $haproxy_statspassword = '',

) {

  file {
    '/etc/haproxy/haproxy.cfg':
      content  => template('spamassassin/1404-proxy.cfg.erb'),
      require  => Package['haproxy'],
      owner    => root,
      notify   => Service['haproxy'];
  }

}
