#/etc/puppet/modules/manifests/ssl/name/wildcard_incubator_apache_org.pp

class ssl::name::wildcard_incubator_apache_org (

  $sslcertcontents             = 'this is a test of contents',
  $sslcertname                 = 'wildcard.incubator.apache.org.crt',
  $sslchaincontent             = 'this is a chain content test',
  $sslchainname                = 'wildcard_incubator.apache.org.chain',
  $sslkeycontents              = 'this is a key contents test',
  $sslkeyname                  = 'wildcard.incubator.apache.org.key',
  $sslcombinedcontents         = 'this is a combined contents test',
  $sslcombinedname             = 'wildcard.incubator.apache.org-combined.cert',
  $sslrootdir                  = '/etc/ssl',
  $sslrootdirgroup             = 'root',
  $sslrootdirowner             = 'root',
  $sslrootdirumask             = '0755',
) {

  file {
    "${sslrootdir}/certs/${sslcertname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslcertcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/private/${sslkeyname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslkeycontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/certs/${sslchainname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslchaincontent,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/private/${sslcombinedname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslcombinedcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
  }
}
