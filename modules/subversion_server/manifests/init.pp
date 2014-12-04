#/etc/puppet/modules/subversion_server/manifests/init.pp

class subversion_server {


  file {
   '/x1/svn/hooks':
     ensure   => present,
     recurse  => true,
     owner    => 'www-data',
     group    => 'svnadmins',
     mode     => '0775',
     source   => "puppet:///modules/subversion_server/hooks";
  }
}
