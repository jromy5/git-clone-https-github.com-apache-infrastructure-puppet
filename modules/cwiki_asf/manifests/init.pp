
 class cwiki_asf (
   $uid = 8999,
   $gid = 8999,
   $group_present = 'present',
   $groupname = 'confluence',
   $groups = [],
   # $service_ensure = 'running',
   # $service_name = 'confluence',
   $shell = '/bin/bash',
   $user_present = 'present',
   $username = 'confluence',

){

    user { "${username}":
         name => "${username}",
         ensure => "${user_present}",
         home => "/home/${username}",
         shell => "${shell}",
         uid => "${uid}",
         gid => "${groupname}",
         groups => $groups,
         managehome => true,
         require => Group["${groupname}"],
    }

    group { "${groupname}":
          name => "${groupname}",
          ensure => "${group_present}",
          gid => "${gid}",
    }

 file {
  '/x1/cwiki':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755';
  '/x1/cwiki/confluence-data':
    ensure => directory,
    owner => 'confluence',
    group => 'confluence',
    mode => '0755';
}

  apache::mod { 'rewrite': }
  apache::mod { 'proxy': }
  apache::mod { 'proxy_http': }

  apache::vhost { 'cwiki-vm2':
      vhost_name => '*',
      servername => 'cwiki-vm2.apache.org',
      port => '80',
      docroot => '/var/www/html',
      serveraliases => ['cwiki-test.apache.org'],
      error_log_file => 'cwiki-test_error.log',
      proxy_pass => [
        { 'path' => '/', 'url' => 'http://127.0.0.1:8888/',
          'reverse_urls' => ['http://127.0.0.1:8888/'] },
      ],
  }

}
