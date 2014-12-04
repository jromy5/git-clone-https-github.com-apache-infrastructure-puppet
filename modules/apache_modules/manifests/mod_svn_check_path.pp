class apache_modules::mod_svn_check_path (
  $required_packages = [],
) {

    require apache_modules

    file { 'mod_svn_check_path':
      path    => '/opt/mod_svn_check_path',
      recurse => true,
      source  => 'puppet:///modules/apache_modules/mod_svn_check_path',
    }

    package { "${required_packages}":
      ensure => latest,
    }

    exec { 'compile mod_svn_check_path':
      command => 'apxs2 -I /usr/include/subversion-1 -i -a -c mod_svn_check_path.c',
      cwd     => '/opt/mod_svn_check_path',
      path    => ['/usr/bin', '/bin', '/usr/sbin'],
      creates => '/usr/lib/apache2/modules/mod_svn_check_path.so',
    }
}
