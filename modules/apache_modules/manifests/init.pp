class apache_modules (
) {

    file { 'mod_svn_check_path':
      eunsure => directory,
      path    => '/opt/mod_svn_check_path',
      recurse => true,
      source  => 'puppet:///modules/apache_modules/mod_svn_check_path',
    }
}
