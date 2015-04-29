#/etc/puppet/modules/stunnel_asf/manifests/init.pp

class stunnel_asf (
  $packages = ['stunnel4'],
  $package_ensure = 'latest',
  $stunnel_enable = true,
  $stunnel_options = '',
) {

  package { $packages:
    ensure => $package_ensure,
  }

  file { 'stunnel_conf':
    path    => '/etc/default/stunnel4',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('stunnel_asf/stunnel4.erb'),
    require => Package['stunnel4'],
  }


}
