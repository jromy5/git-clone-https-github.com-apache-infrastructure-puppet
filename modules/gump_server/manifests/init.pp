#/etc/puppet/modules/gump_server/manifests/init.pp

class gump_server {
  $packages = [
    cvs,
    mercurial,
    bzr,
    darcs,
    nant,
    autoconf,
    automake,
    libtool,
    mysql-server,
    mysql-client,
    python-mysqldb,
    'g++',
    mailutils,
    libexpat1-dev,
    curl,
  ]

  package { 'mono-mcs':
    ensure => absent
  }
  -> apt::key { 'mono-project':
    key => '3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF'
  }
  -> apt::source { 'mono-project':
    location => 'http://download.mono-project.com/repo/debian',
    repos    => 'main',
    release  => 'wheezy',
  }
  -> package { [
    'mono-devel',
    'ca-certificates-mono'
    ]:
    ensure => installed
  }
  -> package { $packages: ensure => installed }

  user { 'gump':
    ensure => present,
    home   => '/home/gump',
    shell  => '/bin/bash',
  }

  -> file { '/home/gump':
    ensure => directory,
    owner  => gump,
    group  => gump,
  }

  -> file { '/home/gump/.forward':
    ensure  => file,
    content => 'general@gump.apache.org',
    owner   => gump,
  }

  -> file { '/home/gump/.gitconfig':
    ensure => file,
    source => 'puppet:///modules/gump_server/.gitconfig',
    owner  => gump,
  }

  file { '/root/.forward':
    ensure  => file,
    content => 'private@gump.apache.org',
  }

  ##################################################
  #              Gump workspace                    #
  ##################################################

  file { '/srv':
    ensure => directory,
  }
    -> file { [
      '/srv/gump',
      '/srv/gump/public',
      '/srv/gump/public/workspace',
      '/srv/gump/public/workspace/log'
    ]:
    ensure  => directory,
    owner   => gump,
    group   => gump,
    require => User['gump'],
  }
  -> vcsrepo { '/srv/gump/public/gump':
    ensure   => present,
    provider => svn,
    source   => 'https://svn.apache.org/repos/asf/gump/live/',
    owner    => gump,
    group    => gump,
    require  => Package['subversion'],
  }
  -> file { '/srv/gump/public/gump/metadata/testbed.xml':
    ensure => file,
    owner  => gump,
    group  => gump,
    source => 'puppet:///modules/gump_server/testbed.xml',
  }
  -> file { "/srv/gump/public/gump/cron/local-env-${::hostname}.sh":
    ensure => file,
    owner  => gump,
    group  => gump,
    source => 'puppet:///modules/gump_server/localenv.sh',
  }
  -> file { "/srv/gump/public/gump/cron/local-post-run-${::hostname}.sh":
    ensure => file,
    owner  => gump,
    group  => gump,
    mode   => '0755',
    source => 'puppet:///modules/gump_server/post-run.sh',
  }

  ##################################################
  #              Required Software                 #
  ##################################################

  file { ['/opt', '/opt/__versions__']:
    ensure => directory,
  }
  -> gump_server::opt_package { 'maven-1.1':
    url      => 'https://archive.apache.org/dist/maven/maven-1/1.1/binaries/maven-1.1.zip',
    linkname => 'maven'
  }
  -> gump_server::opt_package { 'apache-maven-2.2.1':
    url      => 'https://archive.apache.org/dist/maven/maven-2/2.2.1/binaries/apache-maven-2.2.1-bin.zip',
    linkname => 'maven2'
  }
  -> gump_server::opt_package { 'apache-maven-3.3.9':
    url      => 'https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip',
    linkname => 'maven3'
  }
  -> gump_server::opt_package { 'gradle-2.14.1':
    url      => 'https://downloads.gradle.org/distributions/gradle-2.14.1-bin.zip',
    linkname => 'gradle'
  }
  -> gump_server::opt_package { 'repoproxy-0.5':
    url      => 'http://gump.apache.org/repoproxy-0.5.zip',
    linkname => 'repoproxy'
  }

  exec { 'Install nuget':
    command => 'curl https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o /usr/bin/nuget.exe && chmod 755 /usr/bin/nuget.exe',
    creates => '/usr/bin/nuget.exe',
    path    => ['/usr/bin', '/bin', '/usr/sbin'],
  }
}
