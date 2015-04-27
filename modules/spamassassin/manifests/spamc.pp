class spamassassin::spamc (

  $spamd_peers           = '',
  $haproxy_maxconns      = '',
  $haproxy_port          = '',
  $haproxy_mode          = 'tcp',
  $haproxy_statuser      = '',
  $haproxy_statspassword = '',

) { 

  class { "spamassassin::spamc::install::${asfosname}::${asfosrelease}":
    spamd_peers           => $spamd_peers,
    haproxy_maxconns      => $haproxy_maxconns,
    haproxy_port          => $haproxy_port,
    haproxy_mode          => $haproxy_mode,
    haproxy_statsuser     => $haproxy_statsuser,
    haproxy_statspassword => $haproxy_statspassword,
  }
}
