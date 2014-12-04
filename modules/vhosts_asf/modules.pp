class vhost_asf::modules (

  $modules,
) {

      create_resources(apache::mod, $modules)
}
