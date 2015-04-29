#/etc/puppet/modules/gitmirrorupdater/manifests/download_file.pp

define gitmirrorupdater::download_file (
  $site=             '',
  $cwd=              '',
  $creates=          '',
  $require_resource= '',
  $user=             ''
) {

  exec {
    $name:
      command => "wget ${site}/${name} -O ${name}",
      path    => '/usr/bin/:/bin/',
      cwd     => $cwd,
      require => $require_resource,
      user    => $user,
  }
}

