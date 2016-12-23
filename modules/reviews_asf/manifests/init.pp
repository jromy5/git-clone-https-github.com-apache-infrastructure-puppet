# deploy reviewboard

class reviews_asf {

  $reviews_packages = [
    'patch',
  ]

  package { $reviews_packages:
    ensure => present,
  }

  class { 'memcached':
    max_memory => '10%',
    listen_ip  => '127.0.0.1',
    tcp_port   => '11211',
  }

}
