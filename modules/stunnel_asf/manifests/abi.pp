#/etc/puppet/modules/stunnel_asf/manifests/abi.pp

class stunnel_asf::abi (
  $cert_path = '/etc/ssl/certs',
  $cert_name = 'abi.apache.org.crt',
  $rsyncd_password,

) {

  include stunnel_asf

  file { 'abi.conf':
    path    => '/etc/stunnel/abi.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('stunnel_asf/abi.conf.erb'),
    require => Package['stunnel4'],
  }

  file { '.pw-abi':
    path    => '/root/.pw-abi',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('stunnel_asf/rsyncd-password.erb'),
  }

}
