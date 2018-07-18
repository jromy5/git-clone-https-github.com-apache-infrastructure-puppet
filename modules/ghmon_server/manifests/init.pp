#/etc/puppet/modules/whimsy_server/manifests/init.pp


class ghmon_server {

  ####################################################################
  #                      certbot / letsencrypt                       #
  ####################################################################

  exec { 'Download certbot':
    command => '/usr/bin/wget -q https://dl.eff.org/certbot-auto -O /usr/local/bin/certbot-auto',
    creates => '/usr/local/bin/certbot-auto',
  }

  -> file { '/usr/local/bin/certbot-auto':
    mode => '0755'
  }

  cron { 'certbot renew':
    ensure  => present,
    command => '/usr/local/bin/certbot-auto renew --quiet',
    user    => root,
    hour    => [2, 14],
    minute  => '43'
  }
}
