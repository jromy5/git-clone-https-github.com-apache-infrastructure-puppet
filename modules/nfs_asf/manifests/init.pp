# create_resources for nfs defined types

class nfs_asf::server {
  $exports = hiera_hash('nfs::server::export',{})
  create_resources(nfs::server::export, $exports)
  contain nfs::server
}

class nfs_asf::client {
  $mounts = hiera_hash('nfs::client::mount',{})
  create_resources(nfs::client::mount, $mounts)
  contain nfs::client
}

