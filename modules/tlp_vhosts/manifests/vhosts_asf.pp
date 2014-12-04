class tlp_vhosts::vhosts_asf (

  $vhosts,
) {

      create_resources(apache::vhost, $vhosts)
}
