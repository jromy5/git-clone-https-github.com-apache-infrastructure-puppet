# /etc/puppet/modules/apmirror/manifests/init.pp

class apmirror (
  $uid            = 508,
  $gid            = 508,
  $group_present  = 'present',
  $groupname      = 'apmirror',
  $groups         = [],
  $service_ensure = 'running',
  $shell          = '/bin/bash',
  $svnwc_group    = 'svnwc',
  $svnwc_user     = 'svnwc',
  $user_present   = 'present',
  $username       = 'apmirror',
  $packages       = ['libwww-perl'],
){

  package { $packages:
    ensure => present,
  }

  user { $username:
    ensure     => $user_present,
    name       => $username,
    home       => "/home/${username}",
    shell      => $shell,
    uid        => $uid,
    gid        => $groupname,
    groups     => $groups,
    managehome => true,
    require    => [ Group[$groupname], Group[$apbackup::username] ],
  }

  group { $groupname:
    ensure => $group_present,
    name   => $groupname,
    gid    => $gid,
  }

  file { 'apmirror profile':
    ensure  => 'present',
    path    => "/home/${username}/.profile",
    mode    => '0644',
    owner   => $username,
    group   => $groupname,
    source  => 'puppet:///modules/apmirror/home/profile',
    require => User[$username],
  }

  exec { 'apmirror-co':
    command => 'svn co http://svn.apache.org/repos/asf/infrastructure/site-tools/trunk/mirrors/',
    path    => '/usr/bin/:/bin/',
    cwd     => "/home/${username}",
    user    => $username,
    group   => $groupname,
    creates => "/home/${username}/mirrors",
    require => [ Package['subversion'], User[$username] ],
  }

  cron { 'apmirror':
    command => "/home/${username}/mirrors/runmirmon.sh",
    minute  => '19',
    user    => $username,
    require => User[$username],
  }

  # Create symlinks to where the apmirror scripts think the binaries live

  file { '/usr/local/bin/wget':
    ensure => 'link',
    target => '/usr/bin/wget',
  }

  # create mirmon file to allow mirror priming to work

  file { 'mirmon.state':
    ensure  => 'file',
    path    => "/home/${username}/mirrors/mirmon/mirmon.state",
    group   => $groupname,
    owner   => $username,
    require => [ Exec['apmirror-co'], User[$username] ],
  }

  exec { 'create mirmon.mlist':
    command => 'perl mk_mlist mirrors.list mirmon/mirmon.mlist',
    path    => '/usr/bin:/bin',
    cwd     => "/home/${username}/mirrors",
    user    => $username,
    group   => $groupname,
    creates => "/home/${username}/mirrors/mirmon/mirmon.mlist",
    require => Exec['apmirror-co'],
  }

  exec { 'apache.org co':
    command => 'svn co https://svn-master.apache.org/repos/infra/websites/production/www/ www.apache.org',
    path    => '/usr/bin:/bin/',
    cwd     => '/var/www/',
    user    => $svnwc_user,
    group   => $svnwc_group,
    creates => '/var/www/www.apache.org/content',
    require => [ Package['subversion'], User[$svnwc_user], Group[$groupname], Class['apache'] ],
  }

  file { 'writable_mirrors':
    ensure  => 'directory',
    path    => '/var/www/www.apache.org/content/mirrors',
    mode    => '2775',
    owner   => $svnwc_user,
    group   => $groupname,
    require => [ Exec['apache.org co'], User[$svnwc_user] ],
  }

  exec { 'mirmon list prime':
    command => 'perl mirmon -get "all"',
    path    => "/usr/local/bin:/usr/bin:/bin:/home/${username}/mirrors/mirmon",
    cwd     => "/home/${username}/mirrors/mirmon/",
    user    => $username,
    group   => $groupname,
    creates => "/home/${username}/mirrors/mirmon/url-mods",
    # increase to this incase the host takes a while to execute the
    # mirror list priming
    timeout => 600,
    require => [ File['mirmon.state'], Exec['create mirmon.mlist'], Exec['apache.org co'], File['writable_mirrors'] ],
  }
}
