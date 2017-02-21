#/etc/puppet/modules/httpd_modules/manifests/mod_svn_check_path.pp

class httpd_modules::mod_svn_check_path (
  $command           = 'apxs2 -DFILTERING -I /usr/include/subversion-1 -i -a -c mod_svn_check_path.c',
  $creates           = '/usr/lib/apache2/modules/mod_svn_check_path.so',
  $mod_path          = '/opt/mod_svn_check_path',
  $required_packages = ['libsvn-dev', 'libapreq2-dev'],
  $shell_path        = ['/usr/bin', '/bin', '/usr/sbin'],
) {

  require httpd_modules

  file { 'mod_svn_check_path':
    path    => $mod_path,
    recurse => true,
    source  => 'puppet:///modules/httpd_modules/mod_svn_check_path',
  }

  package { $required_packages:
    ensure => latest,
  }

  exec { 'compile mod_svn_check_path':
    command => $command,
    cwd     => $mod_path,
    path    => $shell_path,
    creates => $creates,
  }

}
