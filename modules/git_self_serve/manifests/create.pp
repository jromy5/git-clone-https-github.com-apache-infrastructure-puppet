# git self serve create class.
class git_self_serve::create ( ) {

  file {
    '/usr/local/etc/git_self_serve':
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root';
    '/usr/local/etc/git_self_serve/repocron.py':
      mode   => '0755',
      owner  => 'www-data',
      group  => 'www-data',
      source => 'puppet:///modules/git_self_serve/repocron.py';
  }

  cron { 'reporeq':
    command     => '/usr/local/etc/git_self_serve/repocron.py',
    user        => 'www-data',
    minute      => 20,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }

}
