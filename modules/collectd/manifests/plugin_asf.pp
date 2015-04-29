#/etc/puppet/modules/collectd/manifests/plugin_asf.pp

class collectd::plugin_asf (
) {

  $custom_mysql = hiera('collectd::plugin::mysql::database', {} )
  create_resources(collectd::plugin::mysql::database, $custom_mysql)
}
