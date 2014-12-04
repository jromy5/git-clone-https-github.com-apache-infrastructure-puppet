class vhost_asf::modules (

  $modules,
) {

      require apache

      create_resources(apache::mod, $modules)
}
