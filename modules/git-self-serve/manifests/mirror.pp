define git-self-serve::mirror ( ) {

	file { 
		'/usr/local/etc/git-self-server/mirrorcron.sh':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
			source => "puppet:///modules/git-self-server/mirrorcron.sh";	
		'/usr/local/etc/git-self-server/githubcron.sh':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
			source => "puppet:///modules/git-self-server/githubcron.sh";	
		'/usr/local/etc/git-self-serve/add-webhook.sh':
			mode   => '0755',
			owner  => 'git',
			group  => 'git'
      content => template('git-self-server/add-webhook.sh.erb');
	}

  cron { 'self-serve-mirror':
    command     => '/usr/local/etc/git-self-serve/mirrorcron.sh',
    user        => 'git',
    minute      => 35,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
    require     => Class['git_mirror_asf'],
  }

  cron { 'self-serve-github-update':
    command     => '/usr/local/etc/git-self-serve/githubcron.sh',
    user        => 'git',
    minute      => 40,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
    require     => Class['git_mirror_asf'],
  }

}
