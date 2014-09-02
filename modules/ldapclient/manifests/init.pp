#/etc/puppet/modules/ldapclient/manifests/init.pp

class ldapclient (
  $authorizedkeysfolder = '',
  $authorizedkeysfile   = '',
  $ldapclient_packages  = [],
  $pkgprovider          = '',
  $bashpath             = '',
  $ldapcert             = '',
  $ldapservers          = '',
  $nssbinddn            = '',
  $nssbindpasswd        = '',
) {

  package { $ldapclient_packages: 
    ensure   =>  installed,
  }

  file { 
    "${authorizedkeysfolder}":
      ensure  => directory,
      owner   => 'root',
      mode    => '0750';
    "${authorizedkeysfolder}/${authorizedkeysfile}":
      source  => "puppet:///modules/ldapclient/${authorizedkeysfile}",
      mode    => '0750',
      owner   => 'root';
  }

  class { "ldapclient::install::${asfosname}::${asfosrelease}":
    ldapcert      =>  $ldapcert,
    ldapservers   =>  $ldapservers,
    nssbinddn     =>  $nssbinddn,
    nssbindpasswd =>  $nssbindpasswd,
  }

}
