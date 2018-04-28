#/etc/puppet/modules/spamassassin/manifests/spamc.pp

class spamassassin::spamc (

  $spamd_peers           = '',
  $haproxy_maxconns      = '',
  $haproxy_port          = '',
  $haproxy_mode          = 'tcp',
  $haproxy_statsuser     = '',
  $haproxy_statspassword = '',
  $haproxy_packagelist   = [],

) {

  class { "spamassassin::spamc::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
    spamd_peers           => $spamd_peers,
    haproxy_maxconns      => $haproxy_maxconns,
    haproxy_port          => $haproxy_port,
    haproxy_mode          => $haproxy_mode,
    haproxy_statsuser     => $haproxy_statsuser,
    haproxy_statspassword => $haproxy_statspassword,
    haproxy_packagelist   => $haproxy_packagelist,
  }
}
