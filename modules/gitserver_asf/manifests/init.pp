#/etc/puppet/modules/gitserver_asf/manifests/init.pp

class gitserver_asf (

  $custom_fragment_80: ''
  $custom_fragment_443: ''
  $packages = ['gitweb']


) {

package { $packages: 
  ensure  => installed,
}

file {
  '/etc/gitweb':
    ensure   => directory,
    require  => Package["$packages"],
    owner    => 'root',
    group    => 'www-data',
    mode     => '0750';
  }

apache::vhost { 'git-wip-us-ssl':
    priority        => '99',
    vhost_name      => '*',
    servername      => 'git-wip-us.apache.org',
    port            => '443',
    ssl             => true,
    docroot         => '/x1/git/htocs',
    ssl_cert        => '/etc/ssl/certs/wildcard.apache.org.crt',
    ssl_chain       => '/etc/ssl/certs/wildcard.apache.org.chain',
    ssl_key         => '/etc/ssl/private/wildcard.apache.org.key',
    directories     => [
        {
            path            => '/x1/git/htdocs',
            options         => ['Indexes', 'FollowSymLinks', 'MultiViews', 'ExecCGI'],
            allow_override  => ['All'],
            addhandlers     => [
                {
                    handler     => 'cgi-script',
                    extensions  => ['.cgi']
                }
            ],
        },
    ],
    serveraliases   => ['git1-us-west.apache.org'],
    custom_fragment => $custom_fragment_443,
    error_log_file  => 'git-wip-us_error.log',
  }
}
