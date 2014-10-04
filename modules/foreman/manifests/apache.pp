class foreman::apache {
  class { '::apache':
    default_confd_files => false,
    default_vhost       => false,
  }

  class { '::apache::mod::passenger': }
  class { '::apache::mod::headers': }
}
