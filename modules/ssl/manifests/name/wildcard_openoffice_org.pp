#/etc/puppet/modules/manifests/ssl/name/wildcard_openoffice_org.pp

class ssl::name::wildcard_openoffice_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'wildcard.openoffice.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'wildcard_openoffice.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'wildcard.openoffice.org.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'wildcard.openoffice.org-combined.cert',
  $sslrootdir                  = '/etc/ssl',
  $sslrootdirgroup             = 'root',
  $sslrootdirowner             = 'root',
  $sslrootdirumask             = '0755',
) {

  file {
    "${sslrootdir}/certs/${sslcertname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslcertcontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
    "${sslrootdir}/private/${sslkeyname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslkeycontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
    "${sslrootdir}/certs/${sslchainname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslchaincontent,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
    "${sslrootdir}/private/${sslcombinedname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslcombinedcontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
  }
}
