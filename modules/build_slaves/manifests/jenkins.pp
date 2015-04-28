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
    require => User['jenkins'],
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
  }

  file { '/home/jenkins/tools':
    require => File['/usr/local/jenkins'],
    ensure => 'link',
    target => '/usr/local/jenkins',
  }

  file { '/home/jenkins/.ssh':
    require => User['jenkins'],
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700'
  }

  file { '/home/jenkins/env.sh':
    ensure => present,
    mode   => 0755,
    source => 'puppet:///modules/build_slaves/jenkins_env.sh',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  ssh_authorized_key { 'jenkins':
    ensure  => present,
    require => User['jenkins'],
    user    => 'jenkins',
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAtxkcKDiPh1OaVzaVdc80daKq2sRy8aAgt8u2uEcLClzMrnv/g19db7XVggfT4+HPCqcbFbO3mtVnUnWWtuSEpDjqriWnEcSj2G1P53zsdKEu9qCGLmEFMgwcq8b5plv78PRdAQn09WCBI1QrNMypjxgCKhNNn45WqV4AD8Jp7/8='
  }

  file { '/home/jenkins/.m2':
    require => User['jenkins'],
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755'
  }

  file { '/home/jenkins/.buildr':
    require => User['jenkins'],
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755'
  }

  file { '/home/jenkins/.m2/settings.xml':
    require => File['/home/jenkins/.m2'],
    ensure  => $ensure,
    path    => '/home/jenkins/.m2/settings.xml',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('build_slaves/m2_settings.erb')
  }

  file { '/home/jenkins/.buildr/settings.yaml':
    require => File['/home/jenkins/.buildr'],
    ensure  => $ensure,
    path    => '/home/jenkins/.buildr/settings.yaml',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('build_slaves/buildr_settings.erb')
  }

  file { '/home/jenkins/.npmrc':
    require => File['/home/jenkins'],
    ensure  => $ensure,
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
    mode    => 0644,
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
