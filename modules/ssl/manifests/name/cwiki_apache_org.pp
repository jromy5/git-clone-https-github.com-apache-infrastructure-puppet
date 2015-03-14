#/etc/puppet/modules/manifests/ssl/name/cwiki_apache_org.pp

class ssl::name::cwiki_apache_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'cwiki.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'cwiki.apache.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'cwiki.apache.org.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'cwiki.apache.org-combined.cert',
  $sslrootdir                  = '/etc/ssl',
  $sslrootdirgroup             = 'root',
  $sslrootdirowner             = 'root',
  $sslrootdirumask             = '0755',
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
      mode     =>  "0755";
    "${sslrootdir}/private":
      ensure   =>  directory,
      group    =>  "${sslrootdirgroup}",
      owner    =>  "${sslrootdirowner}",
      mode     =>  "0700";
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
