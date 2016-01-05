#/etc/puppet/modules/vhosts_whimsy/manifests/vhosts.pp

class vhosts_whimsy::vhosts (

  $vhosts,
) {


      create_resources(apache::vhost, preprocess_vhosts($vhosts))
}
