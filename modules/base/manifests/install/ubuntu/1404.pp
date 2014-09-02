class base::install::ubuntu::1404 (
) {

  file { 
    '/usr/local/bin/zsh':
      ensure => link,
      target => '/usr/bin/zsh';
    '/usr/local/bin/bash':
      ensure => link,
      target => '/bin/bash';
  }
}
