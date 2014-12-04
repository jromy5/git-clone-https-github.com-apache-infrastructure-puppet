class apache_modules::mod_svn_check_path (
) {

    require apache_modules

    file { 'mod_svn_check_path':
      path    => '/opt/mod_svn_check_path',
      recurse => true,
      source  => 'puppet:///modules/apache_modules/mod_svn_check_path',
    }
}
