#/etc/puppet/modules/gitmirrorupdater/manifests/init.pp

class gitmirrorupdater (
  $packages = ['python-pyinotify'],
) {

  require git_mirror_asf::user

  package { $packages:
    ensure => present,
  }

  -> file {
    '/usr/local/etc/svn2gitupdate':
      ensure => directory,
      owner  => $git_mirror_asf::user::username,
      group  => $git_mirror_asf::user::groupname;
    '/var/log/svn2gitupdate':
      ensure => directory,
      owner  => $git_mirror_asf::user::username,
      group  => $git_mirror_asf::user::groupname;
    '/etc/init.d/svn2gitupdate':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => "puppet:///modules/gitmirrorupdater/svn2gitupdate.${::asfosname}",
      require => User[$git_mirror_asf::user::username];
  }

  -> gitmirrorupdater::download_file {
    [
      'svn2gitupdate.py',
      'svn2gitupdate.cfg'
    ]:
    site             => 'https://svn.apache.org/repos/infra/infrastructure/trunk/projects/git/svn2gitupdate',
    cwd              => '/usr/local/etc/svn2gitupdate',
    require_resource => File['/usr/local/etc/svn2gitupdate'],
    user             => 'git',
  }

  # Restart daemon if settings change
  file {
    '/usr/local/etc/svn2gitupdate/svn2gitupdate.cfg':
      ensure => file,
      audit  => 'content',
      notify => Service['svn2gitupdate']
  }

  -> service { 'svn2gitupdate':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => File['/etc/init.d/svn2gitupdate'],
  }

}
