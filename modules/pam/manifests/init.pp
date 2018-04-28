#/etc/puppet/modules/pam/manifests/init.pp

class pam (
  ) {

  class { "pam::install::${::asfosname}::${::asfosname}_${::asfosrelease}":
  }

}
