#/etc/puppet/modules/subversionclient/manifests/init.pp

class subversionclient (
  $packages             = [],
  $svn_conf_config      = '',
  $svn_conf_servers     = '',

) {

  package { $packages:
    ensure   =>  installed,
  }

  file { 
    "$svn_conf_config":
      source  => 'puppet:///modules/subversionclient/config',
      owner   => 'root',
      mode    => '640';
    "$svn_conf_servers":
      source  => 'puppet:///modules/subversionclient/servers',
      owner   => 'root',
      mode    => '640';
  }
}
