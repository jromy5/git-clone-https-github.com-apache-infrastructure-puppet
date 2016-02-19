#/etc/puppet/modules/manifests/ssl/name/bai_stunnel.pp

class ssl::name::bai_stunnel (

  $sslcertcontents     = '',
  $sslcertname         = 'bai.apache.org.crt',
  $sslchaincontent     = '',
  $sslchainname        = 'bai.apache.org.ca',
  $sslkeycontents      = '',
  $sslkeyname          = 'bai.apache.org.key',
  $sslcombinedcontents = '',
  $sslcombinedname     = '',
  $sslrootdir          = '/etc/ssl',
  $sslrootdirgroup     = 'root',
  $sslrootdirowner     = 'root',
  $sslrootdirumask     = '0755',
) {

  file {
    "${sslrootdir}/certs/${sslcertname}":
      ensure   => present,
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
      content => $sslchaincontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
  }
}

