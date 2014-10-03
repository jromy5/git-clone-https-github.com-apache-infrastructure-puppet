class foreman::apache {
  class { '::apache':
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
  }

  class { '::apache::mod::passenger': }
}
