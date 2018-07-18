# pdns-recursor

class pdns_recursor (
  $package                    = 'pdns-recursor',
  $service                    = 'pdns-recursor',
  $aaaa_additional_processing = 'off',
  $allow_from                 = ['127.0.0.1/8'],
  $allow_from_file            = undef,
  $auth_zones                 = undef,
  $chroot                     = undef,
  $client_tcp_timeout         = 2,
  $config_dir                 = '/etc/powerdns',
  $daemon                     = 'yes',
  $delegation_only            = undef,
  $disable_edns               = undef,
  $disable_edns_ping          = 'no',
  $disable_packetcache        = 'no',
  $dont_query                 = ['127.0.0.1/8'],
  $entropy_source             = false,
  $export_etc_hosts           = 'off',
  $forward_zones              = undef,
  $forward_zones_file         = undef,
  $forward_zones_recurse      = undef,
  $hint_file                  = undef,
  $ignore_rd_bit              = 'off',
  $local_address              = [::ipaddress_lo],
  $local_port                 = 53,
  $log_common_errors          = 'yes',
  $logging_facility           = undef,
  $lua_dns_script             = undef,
  $max_cache_entries          = 1000000,
  $max_cache_ttl              = 86400,
  $max_mthreads               = 2048,
  $max_negative_ttl           = 3600,
  $max_packetcache_entries    = 500000,
  $max_tcp_clients            = 128,
  $max_tcp_per_client         = 0,
  $network_timeout            = 1500,
  $packetcache_servfail_ttl   = 60,
  $packetcache_ttl            = 3600,
  $pdns_distributes_queries   = 'no',
  $query_local_address        = '0.0.0.0',
  $query_local_address6       = undef,
  $quiet                      = 'yes',
  $remotes_ringbuffer_entries = 0,
  $serve_rfc1918              = undef,
  $server_id                  = undef,
  $setgid                     = 'pdns',
  $setuid                     = 'pdns',
  $single_socket              = 'off',
  $socket_dir                 = '/var/run/',
  $socket_group               = undef,
  $socket_mode                = undef,
  $socket_owner               = undef,
  $spoof_nearmiss_max         = 20,
  $stack_size                 = 200000,
  $threads                    = 2,
  $trace                      = 'off',
) {

  package { $package:
    ensure => present,
  }

  -> file { "${config_dir}/recursor.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[$service],
    content => template('pdns_recursor/recursor.conf.erb'),
  }

  -> service { $service:
    ensure    => running,
    enable    => true,
    hasstatus => false,
    # service name is pdns-recursor, but binary is pdns_recursor,
    # and since no status, help puppet figure it out
    pattern   => 'pdns_recursor',
  }

}


