class firewall_asf (
) {

  $firewall = hiera_hash('firewall',{})
  create_resources(firewall, $firewall)
}
