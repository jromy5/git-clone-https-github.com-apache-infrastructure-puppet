#/etc/puppet/modules/vcsrepo_asf/manifests/init.pp

class vcsrepo_asf {
  $vcsrepo = hiera_hash('vcsrepo',{})
  create_resources(vcsrepo, $vcsrepo)
}

