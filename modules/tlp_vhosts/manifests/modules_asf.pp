class tlp_vhosts::modules_asf (

  $modules,
) {

      create_resources(apache::mod, $modules)
}
