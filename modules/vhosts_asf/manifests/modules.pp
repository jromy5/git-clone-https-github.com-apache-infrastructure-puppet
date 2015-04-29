#/etc/puppet/modules/vhosts_asf/manifests/modules.pp

class vhosts_asf::modules (

  $modules,
) {


      create_resources(apache::mod, $modules)
}
