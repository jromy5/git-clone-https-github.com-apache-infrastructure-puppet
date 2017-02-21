#/etc/puppet/modules/gitserver_asf/manifests/init.pp

class gitserver_asf (

  $custom_fragment_80  = '',
  $custom_fragment_443 = '',
  $packages            = ['gitweb', 'libnet-github-perl',
                          'libnet-ldap-perl', 'swaks'],


) {

package {
  $packages:
    ensure  => installed,
}

file {
  '/x1/git/htdocs':
    ensure => link,
    target => '/x1/git/asfgit-admin/asf/site/htdocs';
  '/x1/git/htdocs/repos':
    ensure => link,
    target => '/x1/git/repos';
  '/etc/gitweb':
    ensure  => directory,
    require => Package[$packages],
    owner   => 'root',
    group   => 'www-data',
    mode    => '0750';
  '/etc/apache2/gitweb.conf':
    ensure  => present,
    source  => 'puppet:///modules/gitserver_asf/gitweb.conf',
    notify  => Service['apache2'],
    require => Package['apache2'];
  '/usr/local/sbin/sendmail':
    ensure => link,
    target => '/usr/sbin/sendmail';
  '/etc/gitconfig':
    ensure => present,
    source => 'puppet:///modules/gitserver_asf/gitconfig';
  }

cron {
  'asfgit-admin update svn authors':
    command     => '/x1/git/asfgit-admin/asf/bin/asfgit-svn-authors && cp /x1/git/repos/svn/authors.txt /x1/git/asfgit-admin/asf/site/htdocs/authors.txt', # lint:ignore:140chars
    environment => 'PATH=/usr/bin/:/bin/',
    user        => 'root',
    minute      => '5',
    hour        => '1',
}

## Unless declared otherwise the default behaviour is to enable these modules
apache::mod { 'authnz_ldap': }
apache::mod { 'ldap': }
apache::mod { 'rewrite': }

apache::vhost {
  'git-wip-us-80':
    priority        => '99',
    vhost_name      => '*',
    servername      => 'git-wip-us.apache.org',
    port            => '80',
    ssl             => false,
    docroot         => '/x1/git/htdocs',
    serveraliases   => ['git1-us-west.apache.org'],
    custom_fragment => $custom_fragment_80,
    error_log_file  => 'git-wip-us_ssl_error.log',
    directories     => [
      {
        path           => '/x1/git/htdocs',
        options        => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
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
  'git-wip-us-ssl':
    priority        => '98',
    vhost_name      => '*',
    servername      => 'git-wip-us.apache.org',
    port            => '443',
    ssl             => true,
    docroot         => '/x1/git/htdocs',
    ssl_cert        => '/etc/ssl/certs/wildcard.apache.org.crt',
    ssl_chain       => '/etc/ssl/certs/wildcard.apache.org.chain',
    ssl_key         => '/etc/ssl/private/wildcard.apache.org.key',
    serveraliases   => ['git1-us-west.apache.org'],
    custom_fragment => $custom_fragment_443,
    error_log_file  => 'git-wip-us_error.log',
    directories     => [
        {
          path           => '/x1/git/htdocs',
          options        => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
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
