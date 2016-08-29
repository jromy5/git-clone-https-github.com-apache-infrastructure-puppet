# git self-serve mirror class
class git_self_serve::mirror (

  $github_token,

) {

  file {
    '/usr/local/etc/git_self_serve':
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root';
    '/usr/local/etc/git_self_serve/mirrorcron.py':
      mode   => '0755',
      owner  => 'git',
      group  => 'git',
      source => 'puppet:///modules/git_self_serve/mirrorcron.py';
    '/usr/local/etc/git_self_serve/githubcron.py':
      mode   => '0755',
      owner  => 'git',
      group  => 'git',
      source => 'puppet:///modules/git_self_serve/githubcron.py';
    '/usr/local/etc/git_self_serve/add-webhook.sh':
      mode    => '0755',
      owner   => 'git',
      group   => 'git',
      content => template('git_self_serve/add-webhook.sh.erb');
  }

  cron { 'self-serve-mirror':
    command     => '/usr/local/etc/git_self_serve/mirrorcron.py',
    user        => 'git',
    minute      => 25,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }

  cron { 'self-serve-github-update':
    command     => '/usr/local/etc/git_self_serve/githubcron.py',
    user        => 'git',
    minute      => 30,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }

}
