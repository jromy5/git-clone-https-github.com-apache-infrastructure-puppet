#/etc/puppet/modules/git-self-serve/manifests/init.pp

class git-self-server ( ) {

file { ['/usr/local/etc/git-self-serve']:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

}
