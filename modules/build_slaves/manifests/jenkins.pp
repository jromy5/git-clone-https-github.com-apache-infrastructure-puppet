#/etc/puppet/modules/build_slaves/manifests/jenkins.pp

include apt

# jenkins class for the build slaves.
class build_slaves::jenkins (
  $username = 'jenkins',
  $groupname = 'jenkins',
  $nexus_password   = '',
  $npmrc_password    = '',
  $jenkins_pub_key  = '',
  $gsr_user = '',
  $gsr_pw = '',
  $jenkins_packages = [],
  $tools = ['ant','clover','findbugs','forrest','java','maven', 'jiracli', 'jbake', 'gradle'],
  $ant = ['apache-ant-1.8.4', 'apache-ant-1.9.4', 'apache-ant-1.9.7', 'apache-ant-1.9.9', 'apache-ant-1.10.1'],
  $clover = ['clover-ant-4.1.2'],
  $findbugs = ['findbugs-2.0.3', 'findbugs-3.0.1'],
  $forrest = ['apache-forrest-0.9'],
  $jiracli = ['jira-cli-2.1.0'],
  $jbake = ['jbake-2.5.1'],
  $gradle_versions = ['3.5', '4.3.1', '4.4.1'],
  # $maven_old = ['apache-maven-3.0.4','apache-maven-3.2.1'],
  $maven = ['apache-maven-2.2.1', 'apache-maven-3.0.4', 'apache-maven-3.0.5', 'apache-maven-3.2.1', 'apache-maven-3.2.5', 'apache-maven-3.3.3', 'apache-maven-3.3.9', 'apache-maven-3.5.0' , 'apache-maven-3.5.2'], # lint:ignore:140chars
  $java_jenkins = ['jdk1.5.0_17-32','jdk1.5.0_17-64','jdk1.6.0_11-32','jdk1.6.0_11-64','jdk1.6.0_20-32','jdk1.6.0_20-64','jdk1.6.0_27-32','jdk1.6.0_27-64','jdk1.6.0_45-32','jdk1.7.0_04','jdk1.7.0_55', 'jdk1.8.0'], # lint:ignore:140chars
  $java_asfpackages = ['harmony-jdk-713673' , 'jdk1.5.0_22-32', 'jdk1.5.0_22-64', 'jdk1.6.0_20-32-unlimited-security', 'jdk1.6.0_45-64', 'jdk1.7.0-32', 'jdk1.7.0-64', 'jdk1.7.0_25-32', 'jdk1.7.0_25-64', 'jdk1.7.0_79-unlimited-security', 'jdk1.7.0_80', 'jdk1.8.0_66-unlimited-security', 'jdk1.8.0_121', 'jdk1.8.0_131', 'jdk1.8.0_144' , 'jdk1.8.0_144-unlimited-security' , 'jdk1.8.0_152' , 'jigsaw-jdk-9-ea-b156', 'jdk-9-ea-b179' , 'jdk-9-b181' , 'jdk-9-b181-unlimited-security' , 'IBMJava2-142' , 'IBMJava2-amd64-142' , 'ibm-java2-i386-50' , 'ibm-java-i386-60' , 'ibm-java2-x86_64-50' , 'ibm-java-x86_64-60', 'ibm-java-x86_64-70', 'ibm-java-x86_64-80' , 'jdk-9.0.1' , 'jdk-10-ea+36' , 'jdk-10_46'], # lint:ignore:140chars
) {

  require stdlib
  require build_slaves

  #define all symlink making iterators
  define build_slaves::mkdir_tools ($tool = $title) {
    file {"/home/${build_slaves::username}/tools/${tool}":
      ensure => directory,
      owner  => $username,
      group  => $groupname,
    }
  }
  #define ant symlinking
  define build_slaves::symlink_ant ($ant_version = $title) {
    file {"/home/${build_slaves::username}/tools/ant/${ant_version}":
      ensure => link,
      target => "/usr/local/asfpackages/ant/${ant_version}",
    }
  }
  #define findbugs symlinking
  define build_slaves::symlink_findbugs ($findbugs_version = $title) {
    file {"/home/${build_slaves::username}/tools/findbugs/${findbugs_version}":
      ensure => link,
      target => "/usr/local/asfpackages/findbugs/${findbugs_version}",
    }
  }
  #define forrest symlinking
  define build_slaves::symlink_forrest ($forrest_version = $title) {
    file {"/home/${build_slaves::username}/tools/forrest/${forrest_version}":
      ensure => link,
      target => "/usr/local/asfpackages/forrest/${forrest_version}",
    }
  }
  #define jbake symlinking
  define build_slaves::symlink_jbake ($jbake_version = $title) {
    file {"/home/${build_slaves::username}/tools/jbake/${jbake_version}":
      ensure => link,
      target => "/usr/local/asfpackages/jbake/${jbake_version}",
    }
  }
  #define jiracli symlinking
  define build_slaves::symlink_jiracli ($jiracli_version = $title) {
    file {"/home/${build_slaves::username}/tools/jiracli/${jiracli_version}":
      ensure => link,
      target => "/usr/local/asfpackages/jiracli/${jiracli_version}",
    }
  }
  #define maven old symlinking (deprecated, remove soon)
  define build_slaves::symlink_maven_old ($maven_old_version = $title) {
    file {"/home/${build_slaves::username}/tools/maven/${maven_old_version}":
      ensure => link,
      target => "/usr/local/${build_slaves::username}/maven/${maven_old_version}",
    }
  }
  #define maven symlinking (installs to /usr/local/asfpackages)
  define build_slaves::symlink_maven ($maven_version = $title) {
    file {"/home/${build_slaves::username}/tools/maven/${maven_version}":
      ensure => link,
      target => "/usr/local/asfpackages/maven/${maven_version}",
    }
  }
  #define java symlinking
  define build_slaves::symlink_jenkins ($javaj = $title) {
    file {"/home/${build_slaves::username}/tools/java/${javaj}":
      ensure => link,
      target => "/usr/local/${build_slaves::username}/java/${javaj}",
    }
  }
  #define java symlinking
  define build_slaves::symlink_asfpackages ($javaa = $title) {
    file {"/home/${build_slaves::username}/tools/java/${javaa}":
      ensure => link,
      target => "/usr/local/asfpackages/java/${javaa}",
    }
  }
  #define gradle symlinking
  define build_slaves::symlink_gradle ($gradleversions = $title) {
    package {"gradle-${gradleversions}":
      ensure => latest,
    } ->
    file {"/home/${build_slaves::username}/tools/gradle/${gradleversions}":
      ensure => link,
      target => "/usr/lib/gradle/${gradleversions}",
    }
  }


  apt::ppa { 'ppa:cwchien/gradle':
    ensure => present,
  } ->
  package { 'gradle': # this installs the latest version which is 4 right now
    ensure => latest,
  }

  package { 'golang':
    ensure => latest,
  }

  group { $groupname:
    ensure => present,
    gid    => 910,
  }

  group { 'docker':
    ensure => present,
  }->

  user { $username:
    ensure     => present,
    uid        => 910,
    require    => Group[$groupname],
    shell      => '/bin/bash',
    managehome => true,
    groups     => ['docker', $username],
  }

  file { "/home/${build_slaves::username}/env.sh":
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/build_slaves/jenkins_env.sh',
    owner  => $username,
    group  => $groupname,
  }

  file { '/etc/ssh/ssh_keys/jenkins.pub':
    ensure => present,
    mode   => '0640',
    source => 'puppet:///modules/build_slaves/jenkins.pub',
    owner  => $username,
    group  => 'root',
  }

  file { "/home/${build_slaves::username}/.m2":
    ensure  => directory,
    require => User['jenkins'],
    owner   => $username,
    group   => $groupname,
    mode    => '0755'
  }

  file { "/home/${build_slaves::username}/.buildr":
    ensure  => directory,
    require => User[$username],
    owner   => $username,
    group   => $groupname,
    mode    => '0755'
  }

  file { "/home/${build_slaves::username}/.gradle":
    ensure  => directory,
    require => User[$username],
    owner   => $username,
    group   => $groupname,
    mode    => '0755'
  }

  file { "/home/${build_slaves::username}/.m2/settings.xml":
    ensure  => present,
    require => File["/home/${build_slaves::username}/.m2"],
    path    => "/home/${build_slaves::username}/.m2/settings.xml",
    owner   => $username,
    group   => $groupname,
    mode    => '0640',
    content => template('build_slaves/m2_settings.erb')
  }

  file { "/home/${build_slaves::username}/.m2/toolchains.xml":
    ensure  => present,
    require => File["/home/${build_slaves::username}/.m2"],
    path    => "/home/${build_slaves::username}/.m2/toolchains.xml",
    owner   => $username,
    group   => $groupname,
    mode    => '0640',
    source  => 'puppet:///modules/build_slaves/toolchains.xml',
  }

  file { "/home/${build_slaves::username}/.buildr/settings.yaml":
    ensure  => present,
    require => File["/home/${build_slaves::username}/.buildr"],
    path    => "/home/${build_slaves::username}/.buildr/settings.yaml",
    owner   => $username,
    group   => $groupname,
    mode    => '0640',
    content => template('build_slaves/buildr_settings.erb')
  }

  file { "/home/${build_slaves::username}/.gradle/gradle.properties":
    ensure  => present,
    require => File["/home/${build_slaves::username}/.gradle"],
    path    => "/home/${build_slaves::username}/.gradle/gradle.properties",
    owner   => $username,
    group   => $groupname,
    mode    => '0640',
    content => template('build_slaves/gradle_properties.erb')
  }

  file { "/home/${build_slaves::username}/.npmrc":
    ensure  => present,
    path    => "/home/${build_slaves::username}/.npmrc",
    owner   => $username,
    group   => $groupname,
    mode    => '0640',
    content => template('build_slaves/npmrc.erb')
  }

    if ($::fqdn == 'jenkins-websites1.apache.org'){
      file { "/home/${build_slaves::username}/.git-credentials":
        ensure  => present,
        path    => "/home/${build_slaves::username}/.git-credentials",
        owner   => $username,
        group   => $groupname,
        mode    => '0640',
        content => template('build_slaves/git-credentials.erb')
      }

      file { "/home/${build_slaves::username}/.gitconfig":
        ensure => present,
        path   => "/home/${build_slaves::username}/.gitconfig",
        owner  => $username,
        group  => $groupname,
        mode   => '0640',
        source => 'puppet:///modules/build_slaves/gitconfig',
      }
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
  
  file { '/usr/local/asfpackages/kill-old-docker.sh':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/build_slaves/kill-old-docker.sh',
  }

  file {
    "/home/${build_slaves::username}/tools/":
      ensure => 'directory',
      owner  => $username,
      group  => $groupname,
      mode   => '0755';
    '/usr/local/asfpackages/':
      ensure => 'directory',
      owner  => $username,
      group  => $groupname,
      mode   => '0755';
  }->

  # populate /home/${build_slaves::username}/tools/ with asf_packages types
  build_slaves::mkdir_tools { $tools: }
  file {'/usr/local/asfpackages/jiracli/':
    ensure  => directory,
    owner   => $username,
    group   => $groupname,
    require => [ User[$username], Package['asf-build-jira-cli-2.1.0'] ],
    recurse => true,
  }
  file {'/usr/local/asfpackages/forrest/':
    ensure  => directory,
    owner   => $username,
    group   => $groupname,
    require => [ User[$username], Package['asf-build-apache-forrest-0.9'] ],
    recurse => true,
  }
  file {'/usr/local/asfpackages/jbake/':
    ensure  => directory,
    owner   => $username,
    group   => $groupname,
    require => [ User[$username], Package['asf-build-jbake-2.5.1'] ],
    recurse => true,
  }

  package { $jenkins_packages:
    ensure => latest,
  }

  # ant symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_ant          { $ant: }
  file { "/home/${build_slaves::username}/tools/ant/latest":
    ensure => link,
    target => '/usr/local/asfpackages/ant/apache-ant-1.10.1',
  }

  # findbugs symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_findbugs     { $findbugs: }
  file { "/home/${build_slaves::username}/tools/findbugs/latest":
    ensure => link,
    target => '/usr/local/asfpackages/findbugs/findbugs-3.0.1',
  }

  # forrest symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_forrest      { $forrest: }
  file { "/home/${build_slaves::username}/tools/forrest/latest":
    ensure => link,
    target => '/usr/local/asfpackages/forrest/apache-forrest-0.9',
  }

  # jbake symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_jbake      { $jbake: }
  file { "/home/${build_slaves::username}/tools/jbake/latest":
    ensure => link,
    target => '/usr/local/asfpackages/jbake/jbake-2.5.1',
  }

  # jiracli symlinks - populate array, make all symlinks, make latest symlink,
  build_slaves::symlink_jiracli      { $jiracli: }
  file { "/home/${build_slaves::username}/tools/jiracli/latest":
    ensure => link,
    target => '/usr/local/asfpackages/jiracli/jira-cli-2.1.0',
  }

  # maven old symlinks - populate array, make all symlinks, make latest symlink
  # build_slaves::symlink_maven_old    { $maven_old: }
  # maven symlinks - populate array, make all symlinks, make latest symlink
  build_slaves::symlink_maven        { $maven: }
  file { "/home/${build_slaves::username}/tools/maven/latest2":
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-2.2.1',
  }
  file { "/home/${build_slaves::username}/tools/maven/latest":
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-3.5.2',
  }
  file { "/home/${build_slaves::username}/tools/maven/latest3":
    ensure => link,
    target => '/usr/local/asfpackages/maven/apache-maven-3.5.2',
  }

  # java symlinks - old java location, new java location, and latest symlinks
  build_slaves::symlink_jenkins { $java_jenkins: }
  build_slaves::symlink_asfpackages  { $java_asfpackages: }
  file { "/home/${build_slaves::username}/tools/java/ibm-1.7-64":
    ensure => link,
    target => '/usr/local/asfpackages/java/ibm-java-x86_64-70',
  }
  file { "/home/${build_slaves::username}/tools/java/latest":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.8.0_144',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.4":
    ensure => link,
    target => '/usr/local/asfpackages/java/j2sdk1.4.2_19',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.5":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.5.0_22-64',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.6":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.6.0_45-64',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.7":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.7.0_80',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.8":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk1.8.0_152',
  }
  file { "/home/${build_slaves::username}/tools/java/latest1.9":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk-9.0.1',
  }
  file { "/home/${build_slaves::username}/tools/java/latest10":
    ensure => link,
    target => '/usr/local/asfpackages/java/jdk-10_46',
  }


  # make gradle symlinks 4.3 is the latest
  build_slaves::symlink_gradle { $gradle_versions: }
  file { "/home/${build_slaves::username}/tools/gradle/4.3":
    ensure => link,
    target => '/usr/lib/gradle/4.3.1',
  }
  file { "/home/${build_slaves::username}/tools/gradle/4.4":
    ensure => link,
    target => '/usr/lib/gradle/4.4.1',
  }


  cron {
    'docker-cleanup':
      hour        => '13',
      command     => '/usr/bin/docker system prune -f',
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }

  cron {
    'docker-cleanup-weekly':
      hour        => '20',
      command     => '/usr/bin/docker system prune -a -f -filter "until=168h"',
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }

  cron {
    'docker-kill-old-containers':
      hour        => '6',
      command     => '/bin/bash /usr/local/asfpackages/kill-old-docker.sh',
      environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
  }


  service { 'apache2':
    ensure => 'stopped',
  }

}
