#/etc/puppet/modules/wiki_asf/manifests/init.pp

class wiki_asf {

  apache::custom_config {
    'wiki.apache.org':
      ensure   => present,
      source   => 'puppet:///modules/wiki_asf/wiki.apache.org.conf',
      confdir  => '/etc/apache2/sites-available',
      priority => '10',
      require  => Class['apache'],
      notify   => Exec['enable-wiki-site'],
  }

  include apache::mod::cache
  include apache::mod::expires
  include apache::mod::rewrite
  include apache::mod::ssl
  include apache::mod::status
  include apache::mod::wsgi

  apache::mod {
    'allowmethods':
      loadfile_name => 'allowmethods.load',
      path          => '/usr/lib/apache2/modules/mod_allowmethods.so';
    'log_debug':
      loadfile_name => 'log_debug.load',
      path          => '/usr/lib/apache2/modules/mod_log_debug.so';
    'log_forensic':
      loadfile_name => 'log_forensic.load',
      path          => '/usr/lib/apache2/modules/mod_log_forensic.so';
  }

  $packages = [ 'libapache2-mod-wsgi' ]

  package {
    $packages:
      ensure =>  installed,
  }

  exec {
    'enable-wiki-site':
      command => '/usr/sbin/a2ensite 10-wiki.apache.org',
      unless  => '/usr/bin/test -f /etc/apache2/sites-enabled/10-wiki.apache.org',
      creates => '/etc/apache2/sites-enabled/10-wiki.apache.org',
  }

  file {
    '/etc/apache2/wiki-abusers':
      ensure  => directory,
      require => Package['apache2'];
    '/etc/apache2/wiki-abusers/abuse-asis':
      source  => 'puppet:///modules/wiki_asf/abuse.asis',
      require => [Package['apache2'],File['/etc/apache2/wiki-abusers']];
    '/usr/local/etc/wikitools':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0750';
    '/usr/local/etc/wikitools/wiki-users.py':
      ensure => present,
      mode   => '0755',
      source => 'puppet:///modules/wiki_asf/tools/wiki-users.py';
  }
}


