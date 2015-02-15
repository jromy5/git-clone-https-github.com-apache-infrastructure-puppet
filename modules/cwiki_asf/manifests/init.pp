
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

  apache::mod { 'rewrite': }
  apache::mod { 'proxy': }
  apache::mod { 'proxy_http': }

  apache::vhost { 'cwiki-vm2':
      priority => '99',
      vhost_name => '*',
      servername => 'cwiki-vm2.apache.org',
      port => '80',
      docroot => '/var/www/html',
      serveraliases => ['cwiki-test.apache.org'],
      error_log_file => 'cwiki-test_error.log',
  }

}
