#/etc/puppet/modules/manifests/ssl/name/bai_stunnel.pp

class ssl::name::bai_stunnel (

  $sslcrlcontents       = '',
  $sslcrlname           = 'bai.apache.org.crl',
  $sslcertcontents      = '',
  $sslcertname          = 'bai.apache.org.crt',
  $sslchaincontents     = '',
  $sslchainname         = 'bai.apache.org.ca',
  $sslkeycontents       = '',
  $sslkeyname           = 'bai.apache.org.key',
  $sslcombinedcontents  = '',
  $sslcombinedname      = '',
  $sslrootdir           = '/etc/ssl',
  $sslrootdirgroup      = 'root',
  $sslrootdirowner      = 'root',
  $sslrootdirumask      = '0755',
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
      require => File["${sslrootdir}/certs"],
      content => $sslcertcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/private/${sslcrlname}":
      ensure  => present,
      require => File["${sslrootdir}/private"],
      content => $sslcrlcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/private/${sslkeyname}":
      ensure  => present,
      require => File["${sslrootdir}/private"],
      content => $sslkeycontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
    "${sslrootdir}/certs/${sslchainname}":
      ensure  => present,
      require => File["${sslrootdir}/certs"],
      content => $sslchaincontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup;
  }
}

