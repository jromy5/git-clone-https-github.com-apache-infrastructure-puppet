# /etc/puppet/modules/datadog_asf/manifests/init.pp

class datadog_asf (
  $snmp_config = {},
) inherits datadog_agent::params {

  if !empty($snmp_config) {

    validate_hash($snmp_config)

    if !has_key($snmp_config, 'init_config') {
      fail("init_config key not found in hash.\nMust have init_config key in hash, and it must be empty")
    }

    if $snmp_config['init_config'] != undef {
      fail("init_config is not empty.\nMust have init_config key in hash, and it must be empty")
    }

    file { "${datadog_agent::params::conf_dir}/snmp.yaml":
      ensure  => file,
      owner   => $datadog_agent::params::dd_user,
      group   => $datadog_agent::params::dd_group,
      mode    => '0600',
      content => template('datadog_asf/snmp.yaml.erb'),
      require => Package[$datadog_agent::params::package_name],
      notify  => Service[$datadog_agent::params::service_name],
    }

  }

}
