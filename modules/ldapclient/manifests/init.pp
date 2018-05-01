#/etc/puppet/modules/ldapclient/manifests/init.pp

class ldapclient (
  $authorizedkeysfolder        = '',
  $authorizedkeysfile          = '',
  $ldapclient_packages         = [],
  $ldapclient_remove_packages  = [],
  $pkgprovider                 = '',
  $bashpath                    = '',
  $ldapcert                    = '',
  $ldapservers                 = '',
  $nssbinddn                   = '',
  $nssbindpasswd               = '',
) {

  package {
    $ldapclient_packages:
      ensure   =>  installed,
  }

  package {
    $ldapclient_remove_packages:
      ensure   =>  purged,
  }

  file {
    $authorizedkeysfolder:
      ensure => directory,
      owner  => 'root',
      mode   => '0750';
    "${authorizedkeysfolder}/${authorizedkeysfile}":
      source => "puppet:///modules/ldapclient/${authorizedkeysfile}",
      mode   => '0750',
      owner  => 'root';
  }

  class { "ldapclient::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
    ldapcert      =>  $ldapcert,
    ldapservers   =>  $ldapservers,
    nssbinddn     =>  $nssbinddn,
    nssbindpasswd =>  $nssbindpasswd,
  }

}
