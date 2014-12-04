class vhosts_asf::vhosts (

  $vhosts,
) {

      require apache

      create_resources(apache::vhost, $vhosts)
}
