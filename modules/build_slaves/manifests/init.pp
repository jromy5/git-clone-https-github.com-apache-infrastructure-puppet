class build_slaves (
  $distro_packages  = [],
  ) {
  
  class { "build_slaves::install::${asfosname}::${asfosrelease}":
  }

  package { $distro_packages: 
    ensure   =>  installed,
  }

}
