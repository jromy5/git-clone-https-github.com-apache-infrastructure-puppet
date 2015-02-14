
 class confluence (
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
}
