#/etc/puppet/modules/manifests/ssl/name/circonus_ca.pp

class ssl::name::circonus_ca (

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
    $sslrootdir:
      ensure => directory,
      group  => $sslrootdirgroup,
      owner  => $sslrootdirowner,
      mode   => $sslrootdirumask;
    "${sslrootdir}/${sslcertname}":
      ensure  => present,
      require => File[$sslrootdir],
      content => $sslcertcontents,
      owner   => $sslrootdirowner,
      group   => $sslrootdirgroup,
      mode    => '0644';
  }
}
