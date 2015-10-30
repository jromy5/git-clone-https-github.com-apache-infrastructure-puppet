#/etc/puppet/modules/manifests/ssl/name/reporting_cloudstack_apache_org.pp

class ssl::name::reporting_cloudstack_apache_org (

  $sslcertcontents             = '',
  $sslcertname                 = 'reporting.cloudstack.apache.org.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'reporting.cloudstack.apache.org.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'reporting.cloudstack.apache.org.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'reporting.cloudstack.apache.org-combined.cert',
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
