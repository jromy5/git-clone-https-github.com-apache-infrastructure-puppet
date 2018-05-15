#/etc/puppet/modules/stunnel_asf/manifests/init.pp

class stunnel_asf (
  $packages        = ['stunnel4'],
  $package_ensure  = 'latest',
  $stunnel_enable  = true,
  $stunnel_options = '',
  $stunnel_host    = 'abi.apache.org',
  $stunnel_port    = '443',
  $cert_path       = '/root/abi.apache.org.crt',
) {

  package { $packages:
    ensure => $package_ensure,
  }

  file {
    'etc_stunnel_conf':
      path    => '/etc/default/stunnel4',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('stunnel_asf/stunnel4.erb'),
      require => Package['stunnel4'];
    'root_abi_cert':
      path   => '/root/abi.apache.org.crt',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/stunnel_asf/abi.apache.org.crt';
    'abi.conf':
      path    => '/etc/stunnel/abi.conf',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('stunnel_asf/abi.conf.erb'),
      require => Package['stunnel4'];
  }

}
