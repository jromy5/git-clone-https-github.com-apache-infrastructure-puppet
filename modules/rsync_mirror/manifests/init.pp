# /etc/puppet/modules/rsync_mirror/manifests/init.pp

class rsync_mirror (
){

  logrotate::rule { 'rsync':
    path         => '/var/log/rsync/rsync',
    rotate       => 7,
    rotate_every => 'day',
    missingok    => true,
    compress     => true,
    compresscmd  => '/bin/bzip2',
    compressext  => '.bz2',
    postrotate   => ['if /etc/init.d/rsync status > /dev/null ; then /etc/init.d/rsync reload > /dev/null; fi;'], # lint:ignore:80chars
  }

  file { 'rsync_hang.pl':
    ensure  => present,
    path    => '/root/rsync_hang.pl',
    owner   => 'root',
    group   => 'root',
    mode    => '0775',
    content => 'puppet:///modules/rsync_mirror/rsync_hang.pl',
  }

  cron { 'kill stale rsync':
    ensure      => present,
    command     => 'to_kill=$(./rsync_hang | tail -1) && if [[ ! -z $to_kill ]] ; then kill -15 $to_kill ; fi', # lint:ignore:80chars
    environment => 'PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    hour        => '0',
    minute      => '15',
    user        => 'root',
    require     => File['rsync_hang.pl'],
  }


  $deny = [
            '150.164.76.110', '202.189.39.33', '209.115.248.62', '220.80.108.131', '131.151.1.23', # lint:ignore:80chars
            '202.172.248.46', '207.45.221.24', '195.219.14.24', '140.109.13.44', '66.79.190.190', # lint:ignore:80chars
            '65.75.153.220', '*.net24.it', '205.209.129.30', '65.75.138.220', '68.165.230.206', # lint:ignore:80chars
            '66.79.180.90', '65.98.68.250', '66.93.45.23', '204.11.32.194', '213.247.34.12', # lint:ignore:80chars
            '221.216.136.159', '208.97.171.5', '72.29.84.91', '202.90.158.134', '202.90.159.136', # lint:ignore:80chars
            '69.63.177.230', '213.229.83.159', '195.130.120.38', '163.28.80.21', '202.183.164.156', # lint:ignore:80chars
            '217.72.200.210', '163.28.80.22', '221.204.254.237', '59.106.2.6', '203.16.234.17', # lint:ignore:80chars
            '194.30.220.74', '69.210.185.1', '208.99.67.22', '149.154.153.83', '140.123.254.5', # lint:ignore:80chars
            '173.220.95.85', '2001:718:2::222', '159.226.21.127', '80.50.248.77', '193.95.66.99', # lint:ignore:80chars
            '221.194.146.165', '118.97.186.204', '2001:4350:0:5:222:19ff:fe5b:c81c', '129.101.159.181', # lint:ignore:80chars
            '89.216.2.122', '204.45.15.106', '202.199.24.90', '1.207.63.21', '204.45.250.242' # lint:ignore:80chars
            ]

  rsync::server::module { 'apache-dist-for-archive':
    path            => '/www/www.apache.org/dist',
    comment         => 'Identical to apache-dist, but without exclusions',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/.rsync.td/', '.svn', '/tmp/'],
    hosts_deny      => ['*'],
    hosts_allow     => ['140.211.11.131', '192.87.106.229', '88.198.26.2'],
  }

  rsync::server::module { 'apache-dist':
    path            => '/www/www.apache.org/dist',
    comment         => 'Apache software distribution (up to 90GB disk)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'yes',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/openoffice/4.1.0', '/openoffice/4.1.1/binaries',
                        '/tmp/', '*.md5', '*.MD5', 'MD5SUM', 'SHA*SUM*',
                        '*.sha1', '*.sha', '*.sha256', '*.sha512', '*.asc',
                        '*.sig', 'KEYS', 'KEYS.txt', '.svn/', '/.rsync.td/',
                        '/zzz/perms', '/zzz/rsync-module/apache-dist-most'],
    hosts_deny      => $deny,
  }

  rsync::server::module { 'apache-dist-most':
    path            => '/www/www.apache.org/dist',
    comment         => 'like apache-dist, without high bandwidth projects (up to 60GB disk)', # lint:ignore:80chars
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'yes',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/tmp/', '*.md5', '*.MD5', '*.sha1', '*.sha',
                        '*.sha256', '*.sha512', '*.asc', 'MD5SUM', 'SHA*SUM*',
                        '*.sig', 'KEYS', 'KEYS.txt', '.svn/', '/.rsync.td/',
                        '/zzz/perms', '/openoffice',
                        '/zzz/rsync-module/apache-dist'],
    hosts_deny      => $deny,
  }

  # This module is no longer used, but leaving for history
#  rsync::server::module { 'SF-aoo-401':
#    path            => '/www/www.apache.org/dist/openoffice/4.0.1',
#    comment         => 'AOO 4.0.1 for Source Forge',
#    uid             => 'nobody',
#    gid             => 'nogroup',
#    max_connections => 80,
#    read_only       => 'yes',
#    list            => 'yes',
#    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
#    exclude         => ['*.md5', '*.MD5', '*.sha1', '*.sha', '*.sha256',
#                        '*.sha512', 'MD5SUM', 'SHA*SUM*', '*.asc', '*.sig',
#                        'KEYS', 'KEYS.txt', '.svn/', '/source'],
#    hosts_deny      => $deny,
#  }

  rsync::server::module { 'www-bootstrap':
    path            => '/www',
    comment         => 'bootstrap www via rsync (not for mirrors)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/www.apache.org/dist/.rsync.td/'],
    hosts_deny      => ['*'],
    hosts_allow     => ['192.87.106.229', '140.211.11.131', '140.211.11.9',
                        '54.172.167.43', '104.130.219.184'],
  }

  rsync::server::module { 'rsync-logs':
    path            => '/var/log/rsync',
    comment         => 'rsync logs for mino (not for mirrors)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    hosts_deny      => ['*'],
    hosts_allow     => ['140.211.11.9', 'localhost'],
  }

}
