class reviews_asf {

  class { 'memcached':
    max_memory  => '10%',
    listen_ip   => '127.0.0.1',
    tcp_port    => '11211',
  }

  
}
