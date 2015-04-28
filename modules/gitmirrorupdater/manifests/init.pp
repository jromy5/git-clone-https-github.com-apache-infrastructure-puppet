class gitmirrorupdater (
) {

  file {
    [ '/usr/local/etc/svn2gitupdate' ]:
      ensure => 'directory',
  }

  file {
    '/x1/git/mirrors':
      ensure => 'directory',
      owner  => 'git',
      group  => 'git',
      mode   => '0755',
  }

  gitmirrorupdater::download_file {
    [
      'svn2gitupdate.py',
      'svn2gitupdate.cfg'
    ]:
    site             => 'https://svn.apache.org/repos/infra/infrastructure/trunk/projects/git/svn2gitupdate',
    cwd              => '/usr/local/etc/svn2gitupdate',
    require_resource => File['/usr/local/etc/svn2gitupdate'],
    user             => 'root',
  }

  # Restart daemon if settings change
  file {
    '/usr/local/etc/svn2gitupdate/svn2gitupdate.cfg':
      ensure => file,
      audit  => 'content',
      notify => Exec['restart_svn2gitupdate']
  }
  
  exec {
    'restart_svn2gitupdate':
      refreshonly => true,
      path        => '/usr/bin/:/bin/',
      cwd         => '/usr/local/etc/svn2gitupdate',
      command     => 'python /usr/local/etc/svn2gitupdate/svn2gitupdate.py restart',
  }
}
