define git-self-serve::mirror ( 

  $nssbinddn = '',
  $nssbingpasswd = '',
  $hipchattoken = '',
  $github_token = '',

) {

	file {
    '/usr/local/etc/git-self-serve':
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root';
		'/usr/local/etc/git-self-serve/mirrorcron.py':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
			source => "puppet:///modules/git-self-serve/mirrorcron.py";	
		'/usr/local/etc/git-self-serve/githubcron.py':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
			source => "puppet:///modules/git-self-serve/githubcron.py";
		'/usr/local/etc/git-self-serve/add-webhook.sh':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
      content => template('git-self-serve/add-webhook.sh.erb');
	}

  cron { 'self-serve-mirror':
    command     => '/usr/local/etc/git-self-serve/mirrorcron.py',
    user        => 'git',
    minute      => 35,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
    require     => Class['git_mirror_asf'],
  }

  cron { 'self-serve-github-update':
    command     => '/usr/local/etc/git-self-serve/githubcron.py',
    user        => 'git',
    minute      => 40,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
    require     => Class['git_mirror_asf'],
  }

}
