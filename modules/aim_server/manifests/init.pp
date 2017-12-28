#/etc/puppet/modules/aim_server/manifests/init.pp

class aim_server (

  $packages            = ['python3-ldap3', 'python3-crypto',
                          'python3-bcrypt', 'python3-gunicorn',
                          'python3-elasticsearch', 'gunicorn3'],

# override below in eyaml

$hipchattoken = '',
$ldapuser  = '',
$ldappass  = ''

) {

  package {
    $packages:
      ensure => installed,
  }

  file { '/var/www/aim':
    source   => 'puppet:///modules/aim_server',
    recurse  => true,
    owner    => 'root',
    group    => 'www-data',
    checksum => 'md5',
    mode     => '0755';
  }

  file { '/var/www/aim/yaml/aim.yaml':
      ensure  => 'present',
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      content => template('aim_server/aim.yaml.erb');
  }

  # Private dir for JSON storage and key(s)
  file {
    '/var/www/aim/private':
      ensure => directory,
      owner  => 'root',
      group  => 'www-data',
      mode   => '0750';
  }

  ## Unless declared otherwise the default behaviour is to enable these modules
  apache::mod { 'authnz_ldap': }
  apache::mod { 'ldap': }
  apache::mod { 'proxy': }
  apache::mod { 'rewrite': }
  apache::mod { 'headers': }
  apache::mod { 'proxy_http': }

  apache::vhost {
    'aim-http':
      priority        => '99',
      vhost_name      => '*',
      servername      => 'aim.apache.org',
      port            => '80',
      ssl             => false,
      docroot         => '/var/www/aim/html',
      manage_docroot  => false,
      serveraliases   => ['aim-test.apache.org'],
      error_log_file  => 'aim_error.log',
      redirect_status => 'permanent',
      redirect_dest   => 'https://aim.apache.org/',
      directories     => [
        {
          path           => '/var/www/aim/html',
          options        => ['Indexes'],
          allow_override => ['All'],
        },
      ],
  }

  apache::vhost {
    'aim-https':
      priority        => '25',
      vhost_name      => '*',
      servername      => 'aim.apache.org',
      port            => '443',
      ssl             => true,
      docroot         => '/var/www/aim/html',
      manage_docroot  => false,
      ssl_cert        => '/etc/ssl/certs/wildcard.apache.org.crt',
      ssl_chain       => '/etc/ssl/certs/wildcard.apache.org.chain',
      ssl_key         => '/etc/ssl/private/wildcard.apache.org.key',
      serveraliases   => ['aim-test.apache.org'],
      custom_fragment => '
            <Location /api/>
                AuthType Basic
                AuthName "ASF Members only"
                AuthLDAPurl "ldaps://ldap-eu-ro.apache.org/ou=people,dc=apache,dc=org?uid"
                AuthLDAPGroupAttribute memberUid
                AuthLDAPRemoteUserIsDN Off
                AuthBasicProvider ldap
                AuthLDAPGroupAttributeIsDN off
                <RequireAny>
                    Require ldap-group cn=member,ou=groups,dc=apache,dc=org
                </RequireAny>
                RewriteEngine On
                RewriteRule .* - [E=PROXY_USER:%{LA-U:REMOTE_USER}]
                RequestHeader set X-Remote-User %{PROXY_USER}e
                RequestHeader unset Authorization
                ProxyPass http://localhost:3456/api/
            </Location>

      ',
      error_log_file  => 'aim-ssl_error.log',
      directories     => [
          {
            path           => '/var/www/aim/html',
            options        => ['Indexes'],
            allow_override => ['All'],
          },
      ],
  }
  # Gunicorn for AIM
  # Run this command unless gunicorn is already running.
  # -w 4 == 4 workers, we can up that if need be.
  exec { '/usr/bin/gunicorn3 -w 4 -b 127.0.0.1:3456 -D handler:application':
    path   => '/usr/bin:/usr/sbin:/bin',
    user   => 'root',
    group  => 'root',
    cwd    =>  '/var/www/aim',
    unless => '/bin/ps ax | /bin/grep -q [g]unicorn3',
  }
}
