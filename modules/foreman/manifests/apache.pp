class foreman::apache {
  class { '::apache':
    default_mods        => false,
    default_confd_files => false,
  }

  class { '::apache::mod::passenger': }
}
