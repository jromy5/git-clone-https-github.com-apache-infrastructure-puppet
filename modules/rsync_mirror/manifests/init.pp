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
    postrotate   => ['if /etc/init.d/rsync status > /dev/null ; then /etc/init.d/rsync reload > /dev/null; fi;'],
  }

  file {
    'rsync_hang.pl':
      ensure => present,
      path   => '/usr/local/bin/rsync_hang.pl',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/rsync_mirror/rsync_hang.pl';
    'kill_stale_rsync.sh':
      ensure  => present,
      path    => '/root/kill_stale_rsync.sh',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/rsync_mirror/kill_stale_rsync.sh',
      require => File['rsync_hang.pl'];
  }

  cron { 'kill stale rsync':
    ensure      => present,
    command     => '/bin/bash /root/kill_stale_rsync.sh',
    environment => "PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", # lint:ignore:double_quoted_strings
    minute      => '15',
    user        => 'root',
    require     => [ File['kill_stale_rsync.sh'], File['rsync_hang.pl'] ],
  }


  $deny = [
            '150.164.76.110', '202.189.39.33', '209.115.248.62', '220.80.108.131', '131.151.1.23',
            '202.172.248.46', '207.45.221.24', '195.219.14.24', '140.109.13.44', '66.79.190.190',
            '65.75.153.220', '*.net24.it', '205.209.129.30', '65.75.138.220', '68.165.230.206',
            '66.79.180.90', '65.98.68.250', '66.93.45.23', '204.11.32.194', '213.247.34.12',
            '221.216.136.159', '208.97.171.5', '72.29.84.91', '202.90.158.134', '202.90.159.136',
            '69.63.177.230', '213.229.83.159', '195.130.120.38', '163.28.80.21', '202.183.164.156',
            '217.72.200.210', '163.28.80.22', '221.204.254.237', '59.106.2.6', '203.16.234.17',
            '194.30.220.74', '69.210.185.1', '208.99.67.22', '149.154.153.83', '140.123.254.5',
            '173.220.95.85', '2001:718:2::222', '159.226.21.127', '80.50.248.77', '193.95.66.99',
            '221.194.146.165', '118.97.186.204', '2001:4350:0:5:222:19ff:fe5b:c81c', '129.101.159.181',
            '89.216.2.122', '204.45.15.106', '202.199.24.90', '1.207.63.21', '204.45.250.242'
            ]

  rsync::server::module { 'apache-dist-for-archive':
    path            => '/dist',
    comment         => 'Identical to apache-dist, but without exclusions',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 160,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/.rsync.td/', '.svn', '/tmp/'],
    hosts_deny      => ['*'],
    hosts_allow     => ['140.211.11.131', '192.87.106.229', '88.198.26.2', '140.211.11.105', '127.0.0.1', '37.48.69.226', '37.48.69.238', '163.172.17.199'], # lint:ignore:140chars
  }

  rsync::server::module { 'apache-dist':
    path            => '/dist',
    comment         => 'Apache software distribution (up to 90GB disk)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 160,
    read_only       => 'yes',
    list            => 'yes',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/openoffice/', '/openoffice/',
                        '/tmp/', '*.md5', '*.MD5', 'MD5SUM', 'SHA*SUM*',
                        '*.sha1', '*.sha', '*.sha256', '*.sha512', '*.asc',
                        '*.mds', '*.sha2', '*.sha3', 'META',
                        '*.sig', 'KEYS', 'KEYS.txt', '.svn/', '/.rsync.td/',
                        '/zzz/rsync-module/apache-dist-most',
                        '.revision'],
    hosts_deny      => $deny,
  }

  rsync::server::module { 'apache-dist-most':
    path            => '/dist',
    comment         => 'like apache-dist, without high bandwidth projects (up to 60GB disk)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 160,
    read_only       => 'yes',
    list            => 'yes',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    exclude         => ['/tmp/', '*.md5', '*.MD5', '*.sha1', '*.sha',
                        '*.sha256', '*.sha512', '*.asc', 'MD5SUM', 'SHA*SUM*',
                        '*.mds', '*.sha2', '*.sha3', 'META',
                        '*.sig', 'KEYS', 'KEYS.txt', '.svn/', '/.rsync.td/',
                        '/openoffice',
                        '/zzz/rsync-module/apache-dist', '.revision'],
    hosts_deny      => $deny,
  }

  rsync::server::module { 'priv-mail-arch':
    path            => '/home/apmail/private-arch',
    comment         => 'private mail archives',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    hosts_deny      => ['*'],
    hosts_allow     => ['140.211.11.22'],
  }

  rsync::server::module { 'public-arch':
    path            => '/home/apmail/public-arch',
    comment         => 'public mailing list archives (not for mirrors)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
  }

  # This is for rsync stats on mirror-vm.a.o, talk to henk :)
  rsync::server::module { 'rsync-logs':
    path            => '/var/log/rsync',
    comment         => 'rsync logs for mirror-vm (not for mirrors)',
    uid             => 'nobody',
    gid             => 'nogroup',
    max_connections => 80,
    read_only       => 'yes',
    list            => 'no',
    outgoing_chmod  => 'ug-s,Dugo+rx,Fugo+r,u+w,o-w,-t',
    hosts_deny      => ['*'],
    hosts_allow     => ['140.211.11.9', 'localhost', '37.48.69.238'],
  }
}
