#/etc/puppet/modules/gitserver_asf/manifests/init.pp

class gitserver_dual (

  $custom_fragment_80  = '',
  $custom_fragment_443 = '',
  $packages            = ['gitweb', 'libnet-github-perl',
                          'libnet-ldap-perl', 'swaks',
                          'python-ldap'],


) {

package {
  $packages:
    ensure  => installed,
}

file { '/x1':
  ensure  => directory,
  owner   => 'root',
  group   => 'www-data',
  mode    => '0750',
}
file { '/x1/git':
  ensure  => directory,
  owner   => 'root',
  group   => 'www-data',
  mode    => '0750',
  require => File['/x1'],
}
 
file { '/x1/git/asfgit-dual':
  source   => 'puppet://modules/gitserver_dual',
  recurse  => true,
  owner    => 'root',
  group    => 'www-data',
  mode     => '0750';
}


file {
  '/var/www/.ssh':
    ensure   => directory,
    owner    => 'www-data',
    group    => 'www-data',
    mode     => '0750';
  '/var/www/.ssh/config':
    ensure  => present,
    source   => 'puppet:///modules/gitserver_dual/gitconf/config';
}

file {
  '/x1/git/htdocs':
    ensure  => link,
    target  => '/x1/git/asfgit-dual/htdocs';
  '/x1/git/htdocs/repos':
    ensure  => link,
    target  => '/x1/git/repos';
  '/etc/gitweb':
    ensure   => directory,
    require  => Package[$packages],
    owner    => 'root',
    group    => 'www-data',
    mode     => '0750';
  '/usr/local/sbin/sendmail':
    ensure   => link,
    target   => '/usr/sbin/sendmail';
  '/etc/gitconfig':
    ensure   => present,
    source   => 'puppet:///modules/gitserver_dual/gitconfig';
  }


#cron {
#  'asfgit-admin update svn authors':
#    command     => '/x1/git/asfgit-admin/asf/bin/asfgit-svn-authors && cp /x1/git/repos/svn/authors.txt /x1/git/asfgit-admin/asf/site/htdocs/authors.txt', # lint:ignore:80chars
#    environment => 'PATH=/usr/bin/:/bin/',
#    user        => 'root',
#    minute      => '5',
#    hour        => '1',
#}

## Unless declared otherwise the default behaviour is to enable these modules
apache::mod { 'authnz_ldap': }
apache::mod { 'ldap': }
apache::mod { 'rewrite': }

apache::vhost {
  'git-dual-80':
    priority        => '99',
    vhost_name      => '*',
    servername      => 'git-dual.apache.org',
    port            => '80',
    ssl             => false,
    docroot         => '/x1/git/htdocs',
    serveraliases   => ['matt-storage.apache.org'],
    custom_fragment => $custom_fragment_80,
    error_log_file  => 'git-dual_error.log',
    directories     => [
      {
        path           => '/x1/git/htdocs',
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
  'git-dual-ssl':
    priority        => '98',
    vhost_name      => '*',
    servername      => 'git-dual.apache.org',
    port            => '443',
    ssl             => true,
    docroot         => '/x1/git/htdocs',
    ssl_cert        => '/etc/ssl/certs/wildcard.apache.org.crt',
    ssl_chain       => '/etc/ssl/certs/wildcard.apache.org.chain',
    ssl_key         => '/etc/ssl/private/wildcard.apache.org.key',
    serveraliases   => ['matt-storage.apache.org'],
    custom_fragment => $custom_fragment_443,
    error_log_file  => 'git-dual_ssl_error.log',
    directories     => [
        {
          path           => '/x1/git/htdocs',
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
