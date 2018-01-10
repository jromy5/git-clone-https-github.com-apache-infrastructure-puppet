#/etc/puppet/modules/buildbot_slaves/manifests/rat.pp

  # class for the buildbot slaves making rat reports available.
  class buildbot_slave::rat (

  $projects = [],

) {

require stdlib
require buildbot_slave

  $build_version      = '0.12'
  $rat_build          = "apache-rat-${build_version}"
  $tarball            = "${rat_build}-bin.tar.gz"
  $download_dir       = '/tmp'
  $downloaded_tarball = "${download_dir}/${tarball}"
  $download_url       = "http://apache.org/dist/creadur/${rat_build}/${tarball}"
  $install_dir        = '/home/buildslave/'

  file {
    '/home/buildslave/slave/rat-buildfiles':
      ensure  => 'directory',
      owner   => $buildbot_slave::username,
      group   => $buildbot_slave::groupname,
      mode    => '0755',
      require => [Group[$buildbot_slave::groupname]];
    '/home/buildslave/rat-output.xsl':
      ensure => 'present',
      source => 'puppet:///modules/buildbot_slave/rat-output.xsl',
      mode   => '0644',
      owner  => $buildbot_slave::username,
      group  => $buildbot_slave::groupname;
  }

  # define buildbot slave project xml directories
  define buildbot_slave::rats ($project = $title) {
    file {"/home/buildslave/slave/rat-buildfiles//${project}.xml":
      ensure  => present,
      owner   => $buildbot_slave::username,
      group   => $buildbot_slave::groupname,
      mode    => '0640',
      source  => "puppet:///modules/buildbot_slave/${project}.xml",
      require => [Package['ant'],File['/home/buildslave/slave/rat-buildfiles'],Group[$buildbot_slave::groupname]];
    }
  }

# download RAT
  exec {
    'download-rat':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-rat'],
  }

# extract the download and move it
  exec {
    'extract-rat':
      command => "/bin/tar -xvzf ${tarball} && mv ${rat_build}/${rat_build}.jar ${install_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/${rat_build}.jar",
      timeout => 1200,
      require => [File[$downloaded_tarball]],
      onlyif  => "/usr/bin/test -d ${install_dir}",
  }

  buildbot_slave::rats { $projects: }

}
