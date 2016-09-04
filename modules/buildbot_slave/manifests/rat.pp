#/etc/puppet/modules/buildbot_slaves/manifests/rat.pp

  # class for the buildbot slaves making rat reports available.
  class buildbot_slave::rat (
  # $project_name: Project name without Apache prefix: example: 'OpenOffice' : default empty
  $project_name  = '',
  # $src_dir: Matches the build name: example: 'openoffice-nightly-rat' : default current dir.
  $src_dir       = '.',
  # $build_dir: Default is 'build' and appends to $src_dir
  $build_dir     = 'build',
  # $build_version: Whatever version the project is building, default trunk.
  $build_version = 'TRUNK',
  # $report_file: the xml output of the rat report (to be uploaded to master) : default 'rat-output.xml' 
  $report_file   = 'rat-output.xml',
  # $rat_excludes: A file in the source checkout that contains a list of patterns to exclude from the RAT check.
  # $rat_excludes: example: /path/to/rat-excludes : $src_dir is prepended automatically.
  $rat_excludes  = '',
) {

require stdlib
require buildbot_slave

  file {
    '/home/buildslave/slave/rat-buildfiles/rat.xml':
    ensure  => present,
    path    => '/home/buildslave/slave/rat-buildfiles/rat.xml',
    owner   => 'buildbot_slave::username',
    group   => 'buildbot_slave::groupname',
    mode    => '0640',
    content => template('buildbot_slave/rat.xml.erb'),
    require => [Package['ant'],File['/home/buildslave/slave/rat-buildfiles'],Group['buildbot_slave::groupname']];

    '/home/buildslave/slave/rat-buildfiles':
    ensure  => 'directory',
    owner   => 'buildbot_slave::username',
    group   => 'buildbot_slave::groupname',
    mode    => '0755',
    require => [Group['buildbot_slave::groupname']];
  }

}
