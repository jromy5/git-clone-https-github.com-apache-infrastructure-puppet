
class svnwcsub (
  $uid            = $svnwcsub::params::uid,
  $gid            = $svnwcsub::params::gid,
  $conf_path      = $svnwcsub::params::conf_path,
  $conf_file      = $svnwcsub::params::conf_file,
  $groupname      = $svnwcsub::params::groupname,
  $groups         = $svnwcsub::params::groups,
  $service_ensure = $svnwcsub::params::service_ensure,
  $service_name   = $svnwcsub::params::service_name,
  $shell          = $svnwcsub::params::shell,
  $username       = $svnwcsub::params::username

) inherits svnwcsub::params {
    
    require stdlib

    unless is_integer($uid) {
        fail('Invalid UID. Should be integer')
    }

    validate_string($service_ensure)


    anchor { 'svnwcsub::begin': } ->
    class { '::svnwcsub::user': } ->
    class { '::svnwcsub::config': } ~>
    class { '::svnwcsub::service': } ->
    anchor { 'svnwcsub::end': }
}
