#/etc/puppet/modules/build_slaves/manifests/jenkins.pp

include apt

# jenkins class for the build slaves.
class build_slaves::jenkins (
  $nexus_password   = '',
  $npmrc_password    = '',
  $jenkins_pub_key  = '',
  $jenkins_packages = [],
  $tools = ['ant','clover','findbugs','forrest','java','maven', 'jiracli'],
  $ant_old = ['apache-ant-1.9.4'],
  $ant = ['apache-ant-1.8.4','apache-ant-1.9.7'],
  $clover = ['clover-ant-4.1.1'],
  $findbugs = ['findbugs-2.0.3'],
  $forrest = ['apache-forrest-0.9'],
  $jiracli = ['jira-cli-2.1.0'],
  # $maven_old = ['apache-maven-3.0.4','apache-maven-3.2.1'],
  $maven = ['apache-maven-2.2.1', 'apache-maven-3.0.4', 'apache-maven-3.0.5', 'apache-maven-3.2.1', 'apache-maven-3.2.5', 'apache-maven-3.3.3', 'apache-maven-3.3.9'],
  $java_jenkins = ['ibm-1.4-32', 'ibm-1.4-64', 'ibm-1.5-32', 'ibm-1.5-64', 'ibm-1.6-32', 'ibm-1.6-64', 'harmony-1.5-64', 'jdk1.5.0_17-32','jdk1.5.0_17-64','jdk1.5.0_22-32','jdk1.5.0_22-64','jdk1.6.0_11-32','jdk1.6.0_11-64','jdk1.6.0_20-32','jdk1.6.0_20-32-unlimited-security','jdk1.6.0_20-64','jdk1.6.0_27-32','jdk1.6.0_27-64','jdk1.6.0_45-32','jdk1.6.0_45-64','jdk1.7.0_04','jdk1.7.0_25-32','jdk1.7.0_25-64','jdk1.7.0-32','jdk1.7.0_55','jdk1.7.0-64','jdk1.8.0'],
  $java_asfpackages = ['jdk1.7.0_79-unlimited-security', 'jdk1.7.0_80', 'jdk1.8.0_66-unlimited-security', 'jdk1.8.0_92', 'jdk1.8.0_102', 'jdk-9-ea-b128', 'jdk-9-ea-b132', 'jdk-9-ea-b139', 'ibm-java-x86_64-80'],
) {

  require stdlib
  require build_slaves

  #define all symlink making iterators
  define build_slaves::mkdir_tools ($tool = $title) {
    file {"/home/jenkins/tools/${tool}":
      ensure => directory,
      owner  => 'jenkins',
      group  => 'jenkins',
    }
  }
  #define ant old symlinking
  define build_slaves::symlink_ant_old ($ant_old_version = $title) {
    file {"/home/jenkins/tools/ant/${ant_old_version}":
      ensure => link,
      target => "/usr/local/jenkins/ant/${ant_old_version}",
    }
  }
  #define ant symlinking
  define build_slaves::symlink_ant ($ant_version = $title) {
    file {"/home/jenkins/tools/ant/${ant_version}":
      ensure => link,
      target => "/usr/local/asfpackages/ant/${ant_version}",
    }
  }
  #define findbugs symlinking
  define build_slaves::symlink_findbugs ($findbugs_version = $title) {
    file {"/home/jenkins/tools/findbugs/${findbugs_version}":
      ensure => link,
      target => "/usr/local/jenkins/findbugs/${findbugs_version}",
    }
  }
  #define forrest symlinking
  define build_slaves::symlink_forrest ($forrest_version = $title) {
    file {"/home/jenkins/tools/forrest/${forrest_version}":
      ensure => link,
      target => "/usr/local/jenkins/forrest/${forrest_version}",
    }
  }
  #define jiracli symlinking
  define build_slaves::symlink_jiracli ($jiracli_version = $title) {
    file {"/home/jenkins/tools/jiracli/${jiracli_version}":
      ensure => link,
      target => "/usr/local/jenkins/jiracli/${jiracli_version}",
    }
  }
  #define maven old symlinking (deprecated, remove soon)
  define build_slaves::symlink_maven_old ($maven_old_version = $title) {
    file {"/home/jenkins/tools/maven/${maven_old_version}":
      ensure => link,
      target => "/usr/local/jenkins/maven/${maven_old_version}",
    }
  }
  #define maven symlinking (installs to /usr/local/asfpackages)
  define build_slaves::symlink_maven ($maven_version = $title) {
    file {"/home/jenkins/tools/maven/${maven_version}":
      ensure => link,
      target => "/usr/local/asfpackages/maven/${maven_version}",
    }
  }
  #define java symlinking
  define build_slaves::symlink_jenkins ($javaj = $title) {
    file {"/home/jenkins/tools/java/${javaj}":
      ensure => link,
      target => "/usr/local/jenkins/java/${javaj}",
    }
  }
  #define java symlinking
  define build_slaves::symlink_asfpackages ($javaa = $title) {
    file {"/home/jenkins/tools/java/${javaa}":
      ensure => link,
      target => "/usr/local/asfpackages/java/${javaa}",
    }
  }

  apt::ppa { 'ppa:cwchien/gradle':
    ensure => present,
  } ->
  package { 'gradle':
    ensure => latest,
  }

  apt::ppa { 'ppa:ubuntu-lxc/lxd-stable':
    ensure => present,
  }->

  package { 'golang':
    ensure => latest,
  }

  group { 'jenkins':
    ensure => present,
  }

  group { 'docker':
    ensure => present,
  }->

  user { 'jenkins':
    ensure     => present,
    require    => Group['jenkins'],
    shell      => '/bin/bash',
    managehome => true,
    groups     => ['docker', 'jenkins'],
  }

  file { '/home/jenkins/env.sh':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/build_slaves/jenkins_env.sh',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/etc/ssh/ssh_keys/jenkins.pub':
    ensure => present,
    mode   => '0640',
    source => 'puppet:///modules/build_slaves/jenkins.pub',
    owner  => 'jenkins',
    group  => 'root',
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
    source  => 'puppet:///modules/build_slaves/toolchains.xml',
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

  file {'/home/jenkins/tools/':
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0755',
  }->

  # populate /home/jenkins/tools/ with asf_packages types
  build_slaves::mkdir_tools { $tools: }
  file {'/usr/local/jenkins/jiracli/':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => [ User['jenkins'], Package['asf-build-jira-cli-2.1.0'] ],
    recurse => true,
  }
  file {'/usr/local/jenkins/forrest/':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => [ User['jenkins'], Package['asf-build-apache-forrest-0.9'] ],
    recurse => true,
  }

  package { $jenkins_packages:
    ensure => latest,
  }

  # ant_old symlinks - populate array, make all symlinks
  build_slaves::symlink_ant_old          { $ant_old: }

  # ant symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_ant          { $ant: }
  file { '/home/jenkins/tools/ant/latest':
    ensure => link,
    target => '/usr/local/asfpackages/ant/apache-ant-1.9.7',
  }

  # findbugs symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_findbugs     { $findbugs: }
  file { '/home/jenkins/tools/findbugs/latest':
    ensure => link,
    target => '/usr/local/jenkins/findbugs/findbugs-2.0.3',
  }

  # forrest symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_forrest      { $forrest: }
  file { '/home/jenkins/tools/forrest/latest':
    ensure => link,
    target => '/usr/local/jenkins/forrest/apache-forrest-0.9',
  }

  # jiracli symlinks - populate array, make all symlinks, make latest symlink,
  build_slaves::symlink_jiracli      { $jiracli: }
  file { '/home/jenkins/tools/jiracli/latest':
    ensure => link,
    target => '/usr/local/jenkins/jiracli/jira-cli-2.1.0',
  }

  # maven old symlinks - populate array, make all symlinks, make latest symlink
  # build_slaves::symlink_maven_old    { $maven_old: }
  # maven symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_maven        { $maven: }
  file { '/home/jenkins/tools/maven/latest2':
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-2.2.1',
  }
  file { '/home/jenkins/tools/maven/latest':
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-3.3.9',
  }
  file { '/home/jenkins/tools/maven/latest3':
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-3.3.9',
  }

  # java symlinks - old java location, new java location, and latest symlinks
  build_slaves::symlink_jenkins { $java_jenkins: }
  build_slaves::symlink_asfpackages  { $java_asfpackages: }
  file { '/home/jenkins/tools/java/ibm-1.7-64':
    ensure => link,
    target => '/usr/local/asfpackages/java/ibm-java-x86_64-70',
  }
  file { '/home/jenkins/tools/java/latest':
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.8.0_102',
  }
  file { '/home/jenkins/tools/java/latest1.4':
    ensure => link,
    target => '/usr/local/jenkins/java/j2sdk1.4.2_19',
  }
  file { '/home/jenkins/tools/java/latest1.5':
    ensure => link,
    target => '/usr/local/jenkins/java/jdk1.5.0_22-64',
  }
  file { '/home/jenkins/tools/java/latest1.6':
    ensure => link,
    target => '/usr/local/jenkins/java/jdk1.6.0_45-64',
  }
  file { '/home/jenkins/tools/java/latest1.7':
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.7.0_80',
  }
  file { '/home/jenkins/tools/java/latest1.8':
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.8.0_102',
  }

  service { 'apache2':
    ensure => 'stopped',
  }

}
