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

  file {
    '/var/www/etherpad-lite/asf':
      ensure => directory,
      mode   => '0755',
      owner  => $username,
      group  => $group;
    '/var/www/etherpad-lite/asf/pads.cgi':
      mode   => '0755',
      owner  => $username,
      group  => $group,
      source => 'puppet:///modules/pad_asf/pads.cgi';
  }

}
