
class tlp_vhosts (
    $uid = $tlp_vhosts::params::uid,
    $gid = $tlp_vhosts::params::gid,
) inherits tlp_vhosts::params {
    
    require stdlib

    unless is_integer($uid) {
        fail('Invalid UID. Should be integer')
    }

    unless is_integer($gid) {
        fail('Invalid GID. Should be integer')
    }

    anchor { 'tlp_vhosts::begin': } ->
    class { '::tlp_vhosts::compat': } ->
    class { '::tlp_vhosts::base': } ->
    class { '::tlp_vhosts::config': } ->
    anchor { 'tlp_vhosts::end': }
}
