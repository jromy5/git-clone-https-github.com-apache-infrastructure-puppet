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
  $bz_package,
  $cookiepath        = '/',
  $create_htaccess   = true,
  $cvsbin            = '/usr/bin/cvs',
  $db_check          = true,
  $db_driver         = 'mysql',
  $db_host           = 'localhost',
  $db_name           = 'bugzilla',
  $db_pass           = '',
  $db_port           = 0,
  $db_sock           = '',
  $db_user           = 'bugzilla',
  $defaultquery      = 'resolution=---&emailassigned_to1=1&emailassigned_to2=1&emailreporter2=1&emailcc2=1&emailqa_contact2=1&emaillongdesc3=1&order=Importance&long_desc_type=substring', # lint:ignore:140chars
  $diffpath          = '/usr/bin',
  $index_html        = false,
  $install_root      = '/var/www',
  $interdiffbin      = '/usr/bin/interdiff',
  $maintainer        = '',
  $mta               = 'Sendmail',
  $mybugstemplate    = 'buglist.cgi?resolution=---&amp;emailassigned_to1=1&amp;emailreporter1=1&amp;emailtype1=exact&amp;email1=%userid%',
  $site_wide_secret  = undef,
  $smtp_server       = 'localhost',
  $svn_url           = 'https://svn.apache.org/viewvc?view=rev&rev=',
  $urlbase           = '',
  $webservergroup    = 'www-data',
  $package_ensure    = 'latest',
) {

  require bugzilla

  $bz_confdir = '/etc/bugzilla'

  package { $bz_package:
    ensure => $package_ensure,
    notify => Exec["bugzilla_checksetup_${name}"],
  }

  case $name { # lint:ignore:case_without_default
    'main': {
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
    require     => File[$answerconfigfile],
  }

  exec { "bugzilla_setup_${name}":
    command     => "${docroot}/checksetup.pl ${answerconfigfile}",
    logoutput   => true,
    refreshonly => true,
    require     => File[$answerconfigfile],
  }

  cron { "daily_update_of_${name}_graphs":
    command     => "(cd ${docroot} ; ./collectstats.pl) 2>&1 | grep -v 'Use of uninitialized.*line 31'",
    minute      => 5,
    hour        => 0,
    environment => "PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin\nSHELL=/bin/sh", # lint:ignore:double_quoted_strings
    require     => Class['rootbin_asf'],
  }

}
