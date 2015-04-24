class spamassassin::spamc (
) { 

class { 'haproxy': }


  $spamd_peers       = '',
  $haproxy_maxconns  = '',
  $haproxy_port      = '',
  $haproxy_mode      = 'tcp',

) { 

  class { "spamassassin::spamc::install::${asfosname}::${asfosrelease}":
    spamd_peers       => $spamd_peers,
    haproxy_maxconns  => $haproxy_maxconns,
    haproxy_port      => $haproxy_port,
    haproxy_mode      => $haproxy_mode,
  }
}
