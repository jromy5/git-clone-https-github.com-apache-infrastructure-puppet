#/etc/puppet/modules/wiki_asf/manifests/init.pp

class wiki_asf {

  apache::custom_config { 'wiki.apache.org':
    source    => "puppet:///modules/wiki_asf/wiki.apache.org.conf",
    priority  => '10',
    ensure    => present,
    require   => Class['apache'],
  }

}
