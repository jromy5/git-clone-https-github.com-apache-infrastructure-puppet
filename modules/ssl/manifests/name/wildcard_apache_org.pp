#/etc/puppet/modules/manifests/ssl/name/wildcard_apache_org.pp

class ssl::name::wildcard_apache_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'wildcard.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'wildcard.apache.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'wildcard.apache.org.key',
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
    "${sslrootdir}/${sslcertname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslcertcontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
    "${sslrootdir}/${sslkeyname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslkeycontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
    "${sslrootdir}/${sslchainname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslchaincontent,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
  }
}
