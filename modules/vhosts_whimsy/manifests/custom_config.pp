#/etc/puppet/modules/vhosts_whimsy/manifests/custom_config.pp

class vhosts_whimsy::custom_config (

) {

      $custom_config = hiera('apache::custom_config', {} )
      create_resources(apache::custom_config, $custom_config)
}
