#/etc/puppet/modules/vhosts_whimsy/manifests/modules.pp

class vhosts_whimsy::modules (

  $modules,
) {


      create_resources(apache::mod, preprocess_modules($modules))
}
