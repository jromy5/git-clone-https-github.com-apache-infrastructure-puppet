
class tlp_vhosts (
) {
    

    anchor { 'tlp_vhosts::begin': } ->
    class { '::tlp_vhosts::config': } ->
    anchor { 'tlp_vhosts::end': }
}
