class sysctl_asf (
) {

  $sysctl = hiera_hash('sysctl',{})
  create_resources(sysctl, $sysctl)
}
