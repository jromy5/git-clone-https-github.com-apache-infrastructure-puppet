# /etc/puppet/modules/datadog_asf/manifests/integrations/network.pp

class datadog_asf::integrations::network (
) inherits datadog_agent::params {

  file { "${datadog_agent::params::conf_dir}/network.yaml":
      ensure  => file,
      owner   => $datadog_agent::params::dd_user,
      group   => $datadog_agent::params::dd_group,
      mode    => '0600',
      source  => 'puppet:///modules/datadog_asf/network.yaml',
      require => Package[$datadog_agent::params::package_name],
      notify  => Service[$datadog_agent::params::service_name],
  }

}
