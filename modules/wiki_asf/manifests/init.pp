#/etc/puppet/modules/wiki_asf/manifests/init.pp

class wiki_asf {

  apache::custom_config { 'wiki.apache.org':
    source    => "puppet:///modules/wiki_asf/wiki.apache.org.conf",
    priority  => '10',
    ensure    => present,
    require   => Class['apache'],
  }

  apache::mod::cache
  apache::mod::expires
  apache::mod::rewrite
  apache::mod::ssl
  apache::mod::status
  apache::mod::wsgi

  $packages = [ 'libapache2-mod-wsgi' ]

  package { $packages:
    ensure   =>  installed,
  }
}
