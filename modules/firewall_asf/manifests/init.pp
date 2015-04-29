# /etc/puppet/modules//firewall_asf/manifests/init.pp

class firewall_asf (
) {

  $firewall = hiera_hash('firewall',{})
  create_resources(firewall, $firewall)

  $firewallchain = hiera_hash('firewallchain', {})
  create_resources(firewallchain, $firewallchain)
}
