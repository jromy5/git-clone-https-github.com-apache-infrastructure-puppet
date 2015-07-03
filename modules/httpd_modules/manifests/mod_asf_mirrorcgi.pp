#/etc/puppet/modules/httpd_modules/manifests/mod_asf_mirrorcgi.pp

class httpd_modules::mod_asf_mirrorcgi (
  $command    = 'apxs2 -i -a -c mod_asf_mirrorcgi.c',
  $creates    = '/usr/lib/apache2/modules/mod_asf_mirrorcgi.so',
  $mod_path   = '/tmp/asf_mirrorcgi_module',
  $shell_path = ['/usr/bin', '/bin', '/usr/sbin'],
) {

  require httpd_modules

  file { 'mod_asf_mirrorcgi':
    path    => $mod_path,
    recurse => true,
    source  => 'puppet:///modules/httpd_modules/asf_mirrorcgi_module',
  }

  exec { 'compile_ asf_mirrorcgi_module':
    command => $command,
    cwd     => $mod_path,
    path    => $shell_path,
    creates => $creates,
    notify  => Service['apache2'];
  }

}
