#/etc/puppet/modules/manifests/ssl/name/wildcard_apache_org_2015.pp

class ssl::name::wildcard_apache_org_2015 (

  $sslcertcontents             = '',
  $sslcertname                 = 'wildcard.apache.org_2015.crt',
  $sslchaincontent             = '',
  $sslchainname                = 'wildcard.apache.org_2015.chain',
  $sslkeycontents              = '',
  $sslkeyname                  = 'wildcard.apache.org_2015.key',
  $sslcombinedcontents         = '',
  $sslcombinedname             = 'wildcard.apache.org-combined_2015.cert',
  $sslrootdir                  = '/etc/ssl',
  $sslrootdirgroup             = 'root',
  $sslrootdirowner             = 'root',
  $sslrootdirumask             = '0755',
) {

  file {
    $sslrootdir:
      ensure => directory,
      group  => $sslrootdirgroup,
      owner  => $sslrootdirowner,
      mode   => $sslrootdirumask;
    "${sslrootdir}/certs":
      ensure => directory,
      group  => $sslrootdirgroup,
      owner  => $sslrootdirowner,
      mode   => '0755';
    "${sslrootdir}/private":
      ensure => directory,
      group  => $sslrootdirgroup,
      owner  => $sslrootdirowner,
      mode   => '0700';
    "${sslrootdir}/certs/${sslcertname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslcertcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/private/${sslkeyname}":
      ensure  => present,
      require => File[$sslrootdirg],
      content => $sslkeycontents,
      owner   => $sslrootdirownerg,
      group   => $sslrootdirgroupg;
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
