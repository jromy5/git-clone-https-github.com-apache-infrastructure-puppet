# This resource is designed to manage Bugzilla projects.
#
# == Parameters
#
# [*create_htaccess*]
# create necessary .htaccess files to lock down bugzilla
# [*webservergroup*]
# group that apache runs as
# [*db_driver*]
# driver to use for db access. Mysql is the default.
# [*db_host*]
# host for db
# [*db_name*]
# db name
# [*db_user*]
# who we connect to the database as
# [*db_pass*]
# DB user password.
# [*db_port*]
# Port to connect to database. 0 is default.
# [*db_sock*]
# Socket to connect to database. Will default to the drivers default.
# [*db_check*]
# Should checksetup.pl try to verify that your database setup is correct?
# [*index_html*]
# Create an index.html file.
# [*cvsbin*]
# Locion of cvs binary
# [*interdiffbin*]
# Location of interdiff binary
# [*diffpath*]
# Location of diff home (/usr/bin/)
# [*site_wide_secret*]
# Set the site wide secret

define bugzilla::project (
  $admin_email,
  $admin_password,
  $admin_realname,
  $create_htaccess  = false,
  $webservergroup   = 'www-data',
  $db_driver        = 'mysql',
  $db_host          = 'localhost',
  $db_name          = 'bugzilla',
  $db_user          = 'bugzilla',
  $db_pass          = '',
  $db_port          = 0,
  $db_sock          = '',
  $db_check         = true,
  $index_html       = false,
  $cvsbin           = '/usr/bin/cvs',
  $interdiffbin     = '/usr/bin/interdiff',
  $diffpath         = '/usr/bin',
  $site_wide_secret = '',
  $smtp_server      = 'localhost',
  $install_root     = '/var/www',
  $svn_url          = 'https://svn.apache.org/viewvc?view=rev&rev=',
  $mta              = 'Sendmail',
) {

  require bugzilla

  $bz_confdir = "/etc/bugzilla"

  case $name {
    "main": {
      $docroot          = "${install_root}/bugzilla"
      $localconfigfile  = "${docroot}/localconfig"
      $answerconfigfile = "${bz_confdir}/.puppet/answer"
    }
    /(.*)/: {
      $docroot          = "${install_root}/bugzilla-${name}"
      $localconfigfile  = "${docroot}/localconfig"
      $answerconfigfile = "${bz_confdir}/.puppet/answer.${name}"
    }
  }

  file { $answerconfigfile:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('bugzilla/answer.erb'),
    notify  => Exec["bugzilla_checksetup_${name}"]
  }

  exec { "bugzilla_checksetup_${name}":
    command     => "${docroot}/checksetup.pl ${answerconfigfile}",
    logoutput   => true,
    refreshonly => true,
    notify      => Exec["bugzilla_setup_${name}"],
    require     => File["${answerconfigfile}"],
  }

  exec { "bugzilla_setup_${name}":
    command     => "${docroot}/checksetup.pl ${answerconfigfile}",
    logoutput   => true,
    refreshonly => true,
    require     => File["${answerconfigfile}"],
  }

}
