#/etc/puppet/modules/manifests/ssl/name/wildcard_openoffice_org.pp

class ssl::name::wildcard_openoffice_org (

  $sslcertcontents     = '',
  $sslcertname         = 'wildcard.openoffice.org.crt',
  $sslchaincontent     = '',
  $sslchainname        = 'wildcard_openoffice.org.chain',
  $sslkeycontents      = '',
  $sslkeyname          = 'wildcard.openoffice.org.key',
  $sslcombinedcontents = '',
  $sslcombinedname     = 'wildcard.openoffice.org-combined.cert',
  $sslrootdir          = '/etc/ssl',
  $sslrootdirgroup     = 'root',
  $sslrootdirowner     = 'root',
  $sslrootdirumask     = '0755',
) {

  if !defined(File["${sslrootdir}"]) {
    file {
      "${sslrootdir}":
        ensure => directory,
        group  => 'root',
        owner  => 'root',
        mode   => '0755';
    "${sslrootdir}/certs":
      ensure => directory,
      group  => 'root',
      owner  => 'root',
      mode   => '0755';
    "${sslrootdir}/private":
      ensure => directory,
      group  => 'root',
      owner  => 'root',
      mode   => '0700';
    }
  }

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
