#/etc/puppet/modules/git_asf/manifests/init.pp

class git_asf (
  $client_packages = $git_asf::params::client_packages,
  $daemon_packages = $git_asf::params::daemon_packages,
  $enable_daemon = $git_asf::params::enable_daemon,
  $daemon_user = $git_asf::params::daemon_user,
  $daemon_basepath = $git_asf::params::daemon_basepath,
  $daemon_directory = $git_asf::params::daemon_directory,
  $daemon_options = $git_asf::params::daemon_options,
) inherits git_asf::params {

  include git_asf::git_client

}
