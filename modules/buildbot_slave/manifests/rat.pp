#/etc/puppet/modules/buildbot_slaves/manifests/rat.pp

  # class for the buildbot slaves making rat reports available.
  class buildbot_slave::rat (
  # $project_name: Project name without Apache prefix: example: 'OpenOffice' : default empty
  $project_name  = '',
  # $src_dir: Matches the build name: example: 'openoffice-nightly-rat' : default current dir.
  $src_dir       = '.',
  # $build_dir: Default is 'build' and appends to $src_dir
  $build_dir     = 'build',
  # $build_version: Whatever version of the RAT tool we are using.
  $build_version = '0.12',
  # $report_file: the xml output of the rat report (to be uploaded to master) : default 'rat-output.xml' 
  $report_file   = 'rat-output.xml',
  # $rat_excludes: A file in the source checkout that contains a list of patterns to exclude from the RAT check.
  # $rat_excludes: example: /path/to/rat-excludes : $src_dir is prepended automatically.
  $rat_excludes  = '',
) {

require stdlib
require buildbot_slave


  $rat_build          = "apache-rat-${build_version}"
  $tarball            = "${rat_build}-bin.tar.gz"
  $download_dir       = '/tmp'
  $downloaded_tarball = "${download_dir}/${tarball}"
  $download_url       = "http://apache.org/dist/creadur/${rat_build}/${tarball}"
  $install_dir        = '/home/buildslave/'

  file {
    '/home/buildslave/slave/rat-buildfiles/rat.xml':
    ensure  => present,
    path    => '/home/buildslave/slave/rat-buildfiles/rat.xml',
    owner   => $buildbot_slave::username,
    group   => $buildbot_slave::groupname,
    mode    => '0640',
    content => template('buildbot_slave/rat.xml.erb'),
    require => [Package['ant'],File['/home/buildslave/slave/rat-buildfiles'],Group[$buildbot_slave::groupname]];

    '/home/buildslave/slave/rat-buildfiles':
    ensure  => 'directory',
    owner   => $buildbot_slave::username,
    group   => $buildbot_slave::groupname,
    mode    => '0755',
    require => [Group[$buildbot_slave::groupname]];

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
      command => "/bin/tar -xvzf ${tarball} && mv ${rat_build}.jar ${install_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/${rat_build}.jar",
      timeout => 1200,
      require => [File[$downloaded_tarball]],
      onlyif  => "/usr/bin/test -d ${install_dir}",
  }

}
