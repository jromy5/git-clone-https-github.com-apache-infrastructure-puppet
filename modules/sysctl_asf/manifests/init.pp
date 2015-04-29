#/etc/puppet/modules/sysctl/manifests/init.pp

class sysctl_asf (
) {

  $sysctl = hiera_hash('sysctl',{})
  create_resources(sysctl, $sysctl)
}
