#/etc/puppet/modules/wiki_asf/manifests/init.pp

class wiki_asf {

  apache::custom_config { 'wiki.apache.org':
    source    => "puppet:///modules/wiki_asf/wiki.apache.org.conf",
    priority  => '10',
    ensure    => present,
    require   => Class['apache'],
  }

  include apache::mod::cache
  include apache::mod::expires
  include apache::mod::rewrite
  include apache::mod::ssl
  include apache::mod::status
  include apache::mod::wsgi

  $packages = [ 'libapache2-mod-wsgi' ]

  package { $packages:
    ensure   =>  installed,
  }
}
