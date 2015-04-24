class spamassassin::spamc::install::ubuntu::1404 (
) {
    package { 'haproxy':
      ensure  => installed,
    }

  file {
    '/etc/default/haproxy':
      content  => template(''),
      require  => Package['haproxy'],
      owner    => root,
      notify   => Service['haproxy'];
    '/etc/haproxy/haproxy.cfg':
      content  => template(''),
      require  => Package['haproxy'],
      owner    => root,
      notify   => Service['haproxy'];
  }

  service { 'haproxy':
    hasstatus  => true,
    hasrestart => true,
  }
}
