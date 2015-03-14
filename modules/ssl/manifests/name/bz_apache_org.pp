#/etc/puppet/modules/manifests/ssl/name/bz_apache_org.pp

class ssl::name::bz_apache_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'bz.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'bz.apache.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'bz.apache.org.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'bz.apache.org-combined.cert',
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
