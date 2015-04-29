#/etc/puppet/modules/vhosts_asf/manifests/vhosts.pp

class vhosts_asf::vhosts (

  $vhosts,
) {


      create_resources(apache::vhost, $vhosts)
}
