#/etc/puppet/modules/selfserve/manifests/init.pp

# selfserve class for id.a.o
class selfserve ( ) {

file {
    '/var/www/selfserve/':
      ensure => directory,
      mode   => '0755',
      owner  => 'www-data',
      group  => 'www-data';
    '/var/www/selfserve/index.html':
      mode   => '0755',
      owner  => 'www-data',
      group  => 'www-data',
      source => 'puppet:///modules/selfserve/index.html';
  }

 exec { 'selfserve-co':
    command => 'svn co https://svn.apache.org/repos/infra/infrastructure/selfserve/trunk',
    path    => '/usr/bin/:/bin/',
    cwd     => '/var/www/',
    user    => www-data,
    group   => www-data,
    creates => '/var/www/selfserve',
    require => [ Package['subversion'] ],
  }
}
