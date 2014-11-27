#/etc/puppet/modules/wiki_asf/manifests/init.pp

class wiki_asf {

  apache::custom_config { 'wiki.apache.org':
    source    => "puppet:///modules/wiki_asf/wiki.apache.org.conf",
    confdir   => "/etc/apache2/sites-available",
    priority  => '10',
    ensure    => present,
    require   => Class['apache'],
    notify    => Exec['enable-wiki-site'],
  }

  include apache::mod::cache
  include apache::mod::expires
  include apache::mod::log_debug
  include apache::mod::log_forensic
  include apache::mod::rewrite
  include apache::mod::ssl
  include apache::mod::status
  include apache::mod::wsgi

  $packages = [ 'libapache2-mod-wsgi' ]

  package { $packages:
    ensure   =>  installed,
  }

  exec {'enable-wiki-site':
    command   => "/usr/sbin/a2ensite 10-wiki.apache.org",
    unless    => "/usr/bin/test -f /etc/apache2/sites-enabled/10-wiki.apache.org",
    creates   => "/etc/apache2/sites-enabled/10-wiki.apache.org",
  }

  file {
    '/etc/apache2/wiki-abusers':
      ensure  => directory,
      require => Package['apache2'];
    '/etc/apache2/wiki-abusers/abuse-asis':
      source  => "puppet:///modules/wiki_asf/abuse.asis",
      require => [Package['apache2'],File['/etc/apache2/wiki-abusers']];
  }
}


