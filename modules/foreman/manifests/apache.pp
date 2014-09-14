class foreman::apache {
  include apache::mod::passenger

  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
  }
}
