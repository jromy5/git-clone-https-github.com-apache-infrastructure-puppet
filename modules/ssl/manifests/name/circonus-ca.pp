#/etc/puppet/modules/manifests/ssl/name/circonus-ca.pp

class ssl::name::circonus-ca (

  $sslcertcontents             = '',
  $sslcertname                 = 'circonus-ca.crt',
  $sslchaincontent             = '',
  $sslchainname                = '',
  $sslkeycontents              = '',
  $sslkeyname                  = '',
  $sslcombinedcontents         = '',
  $sslcombinedname             = '',
  $sslrootdir                  = '/etc/collectd',
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
    "${sslrootdir}/${sslcertname}":
      require => File["${sslrootdir}"],
      ensure  => present,
      content => $sslcertcontents,
      owner   => "${sslrootdirowner}",
      group   => "${sslrootdirgroup}",
      mode    => '0644';
  }
}
