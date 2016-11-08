#/etc/puppet/modules/gitbox/manifests/init.pp

class gitbox (

  $custom_fragment_80  = '',
  $custom_fragment_443 = '',
  $packages            = ['gitweb', 'libnet-github-perl',
                          'libnet-ldap-perl', 'swaks',
                          'python-ldap'],


) {

package {
  $packages:
    ensure => installed,
}

file { '/x1':
  ensure => directory,
  owner  => 'root',
  group  => 'www-data',
  mode   => '0750',
}
file { '/x1/repos':
  ensure  => directory,
  owner   => 'root',
  group   => 'www-data',
  mode    => '0750',
  require => File['/x1'],
}

file { '/x1/gitbox':
  source  => 'puppet:///modules/gitbox',
  recurse => true,
  owner   => 'root',
  group   => 'www-data',
  mode    => '0750';
}


file {
  '/var/www/.ssh':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0750';
  '/var/www/.ssh/config':
    ensure => present,
    source => 'puppet:///modules/gitbox/gitconf/config';
}

## Sync log and broken dir
file {
  '/x1/gitbox/broken':
    ensure  => directory,
    require => Package[$packages],
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0750';
  '/x1/gitbox/sync.log':
    ensure => present,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0750';

file {
  '/etc/gitweb':
    ensure  => directory,
    require => Package[$packages],
    owner   => 'root',
    group   => 'www-data',
    mode    => '0750';
  '/usr/local/sbin/sendmail':
    ensure => link,
    target => '/usr/sbin/sendmail';
  '/etc/gitconfig':
    ensure => present,
    source => 'puppet:///modules/gitbox/gitconfig';
  }

## GitWeb modern CSS
file {
  '/usr/share/gitweb':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0750';
  '/usr/share/gitweb/gitweb.css':
    ensure => present,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0750',
    source => 'puppet:///modules/gitbox/htdocs/gitweb.css';
}


## Unless declared otherwise the default behaviour is to enable these modules
apache::mod { 'authnz_ldap': }
apache::mod { 'ldap': }
apache::mod { 'rewrite': }

apache::vhost {
  'gitbox-80':
    priority        => '99',
    vhost_name      => '*',
    servername      => 'gitbox.apache.org',
    port            => '80',
    ssl             => false,
    docroot         => '/x1/gitbox/htdocs',
    serveraliases   => ['gitbox-vm.apache.org'],
    custom_fragment => $custom_fragment_80,
    error_log_file  => 'gitbox_error.log',
    directories     => [
      {
        path           => '/x1/gitbox/htdocs',
        options        => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'], # lint:ignore:80chars
        allow_override => ['All'],
        addhandlers    => [
          {
            handler    => 'cgi-script',
            extensions => ['.cgi']
          }
        ],
      },
    ],
  }

apache::vhost {
  'gitbox-ssl':
    priority        => '25',
    vhost_name      => '*',
    servername      => 'gitbox.apache.org',
    port            => '443',
    ssl             => true,
    docroot         => '/x1/gitbox/htdocs',
    ssl_cert        => '/etc/ssl/certs/wildcard.apache.org.crt',
    ssl_chain       => '/etc/ssl/certs/wildcard.apache.org.chain',
    ssl_key         => '/etc/ssl/private/wildcard.apache.org.key',
    serveraliases   => [gitbox-vm.apache.org'],
    custom_fragment => $custom_fragment_443,
    error_log_file  => 'gitbox-ssl_error.log',
    directories     => [
        {
          path           => '/x1/gitbox/htdocs',
          options        => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'], # lint:ignore:80chars
          allow_override => ['All'],
          addhandlers    => [
            {
              handler    => 'cgi-script',
              extensions => ['.cgi']
            }
          ],
        },
    ],
  }
}
