class vhosts_asf::vhosts (

  $vhosts,
) {


      create_resources(apache::vhost, $vhosts)
}
