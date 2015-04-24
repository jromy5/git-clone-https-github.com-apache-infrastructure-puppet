class spamassassin::spamc (

  $spamd_peers       = '',
  $haproxy_maxconns  = '',
  $haproxy_port      = '',
  $haproxy_mode      = 'tcp',

) { 

  class { "spamassassin::spamc::install::${asfosname}::${asfosrelease}":
    spamd_peers        => $spamd_peers
     haproxy_maxconns  => '',
     haproxy_port      => '',
     haproxy_mode      => 'tcp',
  }
}
