#/etc/puppet/modules/manifests/ssl/name/abi-stunnel.pp

class ssl::name::abi-stunnel (

  $sslcertcontents             = '',
  $sslcertname                 = 'abi.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = '',
  $sslkeycontents              = '',
  $sslkeyname                  = '',
  $sslcombinedcontents         = '',
  $sslcombinedname             = '',
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
    "${sslrootdir}/certs/${sslcertname}":
      require  =>  File["${sslrootdir}"],
      ensure   =>  present,
      content  =>  $sslcertcontents,
      owner    =>  "${sslrootdirowner}",
      group    =>  "${sslrootdirgroup}";
  }

}
