#/etc/puppet/modules/manifests/ssl/name/wildcard_apache_org.pp

class ssl::name::wildcard_apache_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'wildcard.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'wildcard.apache.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'wildcard.apache.org.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'wildcard.apache.org-combined.cert',
  $sslrootdir                  = '/etc/ssl',
  $sslrootdirgroup             = 'root',
  $sslrootdirowner             = 'root',
  $sslrootdirumask             = '0700',
) {

  file { 
    "${sslrootdir}":
      ensure   =>  directory,
      group    =>  "${sslrootdirgroup}",
      owner    =>  "${sslrootdirowner}",
      mode     =>  "${sslrootdirumask}";
    "${sslrootdir}/certs":
      ensure   =>  directory,
      group    =>  "${sslrootdirgroup}",
      owner    =>  "${sslrootdirowner}",
      mode     =>  "${sslrootdirumask}";
    "${sslrootdir}/private":
      ensure   =>  directory,
      group    =>  "${sslrootdirgroup}",
      owner    =>  "${sslrootdirowner}",
      mode     =>  "${sslrootdirumask}";
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
