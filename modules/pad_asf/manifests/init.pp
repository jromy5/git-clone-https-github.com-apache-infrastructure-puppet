#/etc/puppet/modules/pad_asf/manifests/init.pp

class pad_asf (
  $username       = 'eplite',
  $group          = 'root',

) {

  require python

  python::pip {
    'ezt' :
      ensure => present;
  }

  $parent_dir  = '/var/www/etherpad-lite'
  $install_dir = 'asf'

  file {
    "${parent_dir}/${install_dir}":
      ensure  => directory,
      mode    => '0755',
      owner   => $username,
      group   => $group,
      require => [Class['apache'], Class['etherpad_lite']];
    "${parent_dir}/${install_dir}/pads.cgi":
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/pad_asf/pads.cgi';
    "${parent_dir}/${install_dir}/pads.ezt":
      mode   => '0644',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/pad_asf/pads.ezt';
  }

}
