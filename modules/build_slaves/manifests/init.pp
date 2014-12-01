class build_slaves (
  $distro_packages  = [],
  ) {
  
  package { $distro_packages: 
    ensure   =>  installed,
  }

}
