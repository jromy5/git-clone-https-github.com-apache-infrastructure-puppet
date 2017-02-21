#/etc/puppet/modules/git_asf/manifests/params.pp

class git_asf::params (

  $client_packages = ['git', 'git-svn'],
  $daemon_packages = ['git-daemon-sysvinit'],
  $enable_daemon = true,
  $daemon_user = 'gitdaemon',
  $daemon_basepath = '/var/lib',
  $daemon_directory = '/var/lib/git',
  $daemon_options = '',

) {

  validate_bool($enable_daemon)
  validate_string($daemon_user, $daemon_basepath, $daemon_directory, $daemon_options)
  validate_array($client_packages, $daemon_packages)

}
