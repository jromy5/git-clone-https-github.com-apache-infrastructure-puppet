#/etc/puppet/modules/vhosts_asf/manifests/custom_config.pp

class vhosts_asf::custom_config (

) {

      $custom_config = hiera('apache::custom_config', {} )
      create_resources(apache::custom_config, $custom_config)
}
