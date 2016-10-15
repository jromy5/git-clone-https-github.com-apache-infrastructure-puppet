#/etc/puppet/modules/gump_server/manifests/init.pp

class gump_server {
  $packages = [
    cvs,
    mercurial,
    bzr,
    darcs,
    subversion,
    nant,
    autoconf,
    automake,
    libtool,
    mysql-server,
    mysql-client,
    python-mysqldb,
    mono-mcs,
    'g++',
    mailutils,
    libexpat1-dev,
    git,
    curl,
  ]

  package { $packages: ensure => installed }

  user { 'gump':
    ensure => present,
    home   => '/home/gump',
    shell  => '/bin/bash',
  } ->

  file { '/home/gump':
    ensure => directory,
    owner  => gump,
    group  => gump,
  } ->

  file { '/home/gump/.forward':
    ensure => file,
    content => 'general@gump.apache.org',
    owner => gump,
  } ->

  file { '/home/gump/.gitconfig':
    ensure => file,
    source => 'puppet:///modules/gump_server/.gitconfig',
    owner => gump,
  }

  file { '/root/.forward':
    ensure => file,
    content => 'private@gump.apache.org',
  }

  ##################################################
  #              Gump workspace                    #
  ##################################################

  file { '/srv':
    ensure => directory,
  } ->
  file { [ '/srv/gump', '/srv/gump/public',
           '/srv/gump/public/workspace', '/srv/gump/public/workspace/log' ]:
    ensure => directory,
    owner  => gump,
    group  => gump,
    require => User['gump'],
  } ->
  vcsrepo { '/srv/gump/public/gump':
    ensure   => present,
    provider => svn,
    source   => 'https://svn.apache.org/repos/asf/gump/live/',
    owner  => gump,
    group  => gump,
    require => Package['subversion'],
  } ->
  file { '/srv/gump/public/gump/metadata/testbed.xml':
    ensure => file,
    owner  => gump,
    group  => gump,
    source => 'puppet:///modules/gump_server/testbed.xml',
  } ->
  file { "/srv/gump/public/gump/cron/local-env-${hostname}.sh":
    ensure => file,
    owner  => gump,
    group  => gump,
    source => 'puppet:///modules/gump_server/localenv.sh',
  } ->
  file { "/srv/gump/public/gump/cron/local-post-run-${hostname}.sh":
    ensure => file,
    owner  => gump,
    group  => gump,
    mode   => '0755',
    source => 'puppet:///modules/gump_server/post-run.sh',
  }

  ##################################################
  #              Required Software                 #
  ##################################################

  define gump_server::opt_package ($dirname = $title, $url, $linkname) {
    exec { "Add ${dirname}":
      command => "curl ${url} -o ${$dirname}.zip && unzip ${dirname}.zip -d /opt/__versions__",
      creates => "/opt/__versions__/${dirname}",
      path    => ['/usr/bin', '/bin', '/usr/sbin']
    } ->
    file { "/opt/${linkname}":
      ensure => link,
      force  => true,
      target => "/opt/__versions__/${dirname}"
    }
  }

  file { ['/opt', '/opt/__versions__']:
    ensure => directory,
  } ->
  gump_server::opt_package { 'maven-1.1':
    url => 'https://archive.apache.org/dist/maven/maven-1/1.1/binaries/maven-1.1.zip',
    linkname => 'maven'
  } ->
  gump_server::opt_package { 'apache-maven-2.2.1':
    url => 'https://archive.apache.org/dist/maven/maven-2/2.2.1/binaries/apache-maven-2.2.1-bin.zip',
    linkname => 'maven2'
  } ->
  gump_server::opt_package { 'apache-maven-3.3.9':
    url => 'https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip',
    linkname => 'maven3'
  } ->
  gump_server::opt_package { 'gradle-2.14.1':
    url => 'https://downloads.gradle.org/distributions/gradle-2.14.1-bin.zip',
    linkname => 'gradle'
  } ->
  gump_server::opt_package { 'repoproxy-0.5':
    url => 'http://gump.apache.org/repoproxy-0.5.zip',
    linkname => 'repoproxy'
  }
}
