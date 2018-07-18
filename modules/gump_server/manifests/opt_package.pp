#/etc/puppet/modules/gump_server/manifests/opt_package.pp

define gump_server::opt_package ($url, $linkname, $dirname = $title) {
  exec { "Add ${dirname}":
    command => "curl ${url} -o ${dirname}.zip && unzip ${dirname}.zip -d /opt/__versions__",
    creates => "/opt/__versions__/${dirname}",
    path    => ['/usr/bin', '/bin', '/usr/sbin'],
    require => [ Package['curl'], Package['unzip'] ]
  }
  -> file { "/opt/${linkname}":
    ensure => link,
    force  => true,
    target => "/opt/__versions__/${dirname}"
  }
}

