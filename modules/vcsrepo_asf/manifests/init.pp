class vcsrepo_asf {
  $vcsrepo = hiera_hash('vcsrepo',{})
  create_resources(vcsrepo, $vcsrepo)
}

