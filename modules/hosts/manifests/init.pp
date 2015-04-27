#!/etc/puppet/modules/hosts/manifests/init.pp

# Module to arbitrarily add host file entries via hiera

class hosts (
  $hosts = hiera_hash('hosts')
)  {

  create_resources( 'host', $hosts )
}
