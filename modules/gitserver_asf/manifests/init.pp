#/etc/puppet/modules/gitserver_asf/manifests/init.pp

class gitserver_asf (

$packages = ['gitweb']

) {

package { $packages: 
  ensure  => installed,
}

file {
  '/etc/gitweb':
    ensure   => directory,
    require  => Package["$packages"],
    owner    => 'root',
    group    => 'www-data',
    mode     => '0750';
  }

}
