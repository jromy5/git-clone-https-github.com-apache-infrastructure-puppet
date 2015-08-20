#/etc/puppet/modules/build_slaves/manifests/jenkins.pp

class build_slaves::jenkins (
  $nexus_password   = '',
  $npmrc_passwrd    = '',
  $jenkins_pub_key  = '',
  $jenkins_packages = []
  ) {

  require stdlib
  require build_slaves

  group { 'jenkins':
    ensure => present,
  }

  user { 'jenkins':
    ensure     => present,
    require    => Group['jenkins'],
    shell      => '/bin/bash',
    managehome => true,
  }

  file { '/usr/local/jenkins':
    ensure  => directory,
    require => User['jenkins'],
    owner   => 'jenkins',
    group   => 'jenkins',
  }

  file { '/home/jenkins/tools':
    ensure  => 'link',
    require => File['/usr/local/jenkins'],
    target  => '/usr/local/jenkins',
  }

  file { '/home/jenkins/.ssh':
    ensure  => directory,
    require => User['jenkins'],
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700'
  }

  file { '/home/jenkins/env.sh':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/build_slaves/jenkins_env.sh',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  ssh_authorized_key { 'jenkins':
    ensure  => present,
    require => User['jenkins'],
    user    => 'jenkins',
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAtxkcKDiPh1OaVzaVdc80daKq2sRy8aAgt8u2uEcLClzMrnv/g19db7XVggfT4+HPCqcbFbO3mtVnUnWWtuSEpDjqriWnEcSj2G1P53zsdKEu9qCGLmEFMgwcq8b5plv78PRdAQn09WCBI1QrNMypjxgCKhNNn45WqV4AD8Jp7/8=' # lint:ignore:80chars
  }

  file { '/home/jenkins/.m2':
    ensure  => directory,
    require => User['jenkins'],
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755'
  }

  file { '/home/jenkins/.buildr':
    ensure  => directory,
    require => User['jenkins'],
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755'
  }

  file { '/home/jenkins/.m2/settings.xml':
    ensure  => present,
    require => File['/home/jenkins/.m2'],
    path    => '/home/jenkins/.m2/settings.xml',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('build_slaves/m2_settings.erb')
  }

  file { '/home/jenkins/.m2/toolchains.xml':
    ensure  => present,
    require => File['/home/jenkins/.m2'],
    path    => '/home/jenkins/.m2/toolchains.xml',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source => 'puppet:///modules/build_slaves/toolchains.xml',
  }

  file { '/home/jenkins/.buildr/settings.yaml':
    ensure  => present,
    require => File['/home/jenkins/.buildr'],
    path    => '/home/jenkins/.buildr/settings.yaml',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('build_slaves/buildr_settings.erb')
  }

  file { '/home/jenkins/.npmrc':
    ensure  => present,
    require => File['/home/jenkins'],
    path    => '/home/jenkins/.npmrc',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('build_slaves/npmrc.erb')
  }

  file { '/etc/security/limits.d/jenkins.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///modules/build_slaves/jenkins_limits.conf',
    require => File['/etc/security/limits.d'],
  }

  file_line { 'USERGROUPS_ENAB':
    path  => '/etc/login.defs',
    line  => 'USERGROUPS_ENAB no',
    match => '^USERGROUPS_ENAB.*'
  }

  package { $jenkins_packages:
    ensure   => installed,
  }
}
