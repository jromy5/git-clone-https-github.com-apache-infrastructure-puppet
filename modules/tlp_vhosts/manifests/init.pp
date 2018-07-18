#/etc/puppet/modules/tlp_vhosts/manifests.init.pp

class tlp_vhosts (
){

    anchor { 'tlp_vhosts::begin': }
    -> class { '::tlp_vhosts::compat': }
    -> anchor { 'tlp_vhosts::end': }
}
