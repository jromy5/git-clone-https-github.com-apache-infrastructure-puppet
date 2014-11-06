
class tlp_vhosts (
){
    
    anchor { 'tlp_vhosts::begin': } ->
    class { '::tlp_vhosts::compat': } ->
    class { '::tlp_vhosts::config': } ->
    class { '::tlp_vhosts::ssl_vhosts': } ->
    anchor { 'tlp_vhosts::end': }
}
