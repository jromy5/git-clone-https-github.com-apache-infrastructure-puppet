class apache_modules::mod_svn_check_path (
  $args              = '-I /usr/include/subversion-1 -i -a -c',
  $compiler          = 'apxs2',
  $creates           = '/usr/lib/apache2/modules/mod_svn_check_path.so',
  $mod_path          = '/opt/mod_svn_check_path',
  $module            = 'mod_svn_check_path.c',
  $required_packages = ['libsvn-dev'],
  $shell_path        = ['/usr/bin', '/bin', '/usr/sbin'],
) {

    require apache_modules

    file { 'mod_svn_check_path':
      path    => "${mod_path}",
      recurse => true,
      source  => 'puppet:///modules/apache_modules/mod_svn_check_path',
    }

    package { "${required_packages}":
      ensure => latest,
    }

    exec { 'compile mod_svn_check_path':
      command => "${compiler} ${args} ${module}",
      cwd     => "${mod_path}",
      path    => $shell_path,
      creates => "${creates}",
    }

}
