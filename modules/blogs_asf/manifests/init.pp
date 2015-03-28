 class blogs_asf (
   $r_uid = 8998,
   $r_gid = 8998,
   $r_group_present = 'present',
   $r_groupname = 'roller',
   $t_uid = 8997,
   $t_gid = 8997,
   $t_group_present = 'present',
   $t_groupname = 'tomcat',
   $groups = [],
   $service_ensure = 'stopped',
   $service_name = 'roller',
   $shell = '/bin/bash',
   $r_user_present = 'present',
   $r_username = 'roller',
   $t_user_present = 'present,
   $t_username = 'tomcat',
   $required_packages = [''],
){

# install required packages:
    package { $required_packages:
      ensure => 'present',
    }

# roller specific
   $roller_version = '5.1'
   $roller_revision_number = '1'
   $roller_release = "${roller_version}.{roller_revision_number}"
   $mysql_connector_version = '5.1.11'
   $mysql_connector = "mysql-connector-java-${mysql_connector_version}.jar"
   $mysql_connector_dest_dir = '/x1/roller/current/roller/WEB-INF/lib'
   $roller_build = "roller-release-${roller_release}-standard"
   $tarball = "${roller_build}.tar.gz"
   $download_dir = '/tmp'
   $downloaded_tarball = "${download_dir}/${tarball}"
   $download_url = "https://dist.apache.org/repos/dist/release/roller/roller-${roller_version}/${roller_release}/bin/${tarball}"
   $parent_dir = "/x1/roller"
   $install_dir = "${parent_dir}/${roller_build}"
   $server_port = '8008'
   $connector_port = '8080'
   $context_path = '/'
   $current_dir = "${parent_dir}/current"
   $docroot = '/var/www'

   user { "${r_username}":
        name => "${r_username}",
        ensure => "${r_user_present}",
        home => "/home/${r_username}",
        shell => "${shell}",
        uid => "${r_uid}",
        gid => "${r_groupname}",
        groups => $groups,
        managehome => true,
        require => Group["${r_groupname}"],
   }

   group { "${r_groupname}":
         name => "${r_groupname}",
         ensure => "${r_group_present}",
         gid => "${r_gid}",
   }

   user { "${t_username}":
        name => "${t_username}",
        ensure => "${t_user_present}",
        home => "/home/${t_username}",
        shell => "${shell}",
        uid => "${t_uid}",
        gid => "${t_groupname}",
        groups => $groups,
        managehome => true,
        require => Group["${t_groupname}"],
   }

   group { "${t_groupname}":
         name => "${t_groupname}",
         ensure => "${t_group_present}",
         gid => "${t_gid}",
   }
}
