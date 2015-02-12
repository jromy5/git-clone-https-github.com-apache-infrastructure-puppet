
class stunnel_asf::abi (
  $cert_path = '/etc/ssl/certs',
  $cert_name = 'abi.apache.org.crt',

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

}
