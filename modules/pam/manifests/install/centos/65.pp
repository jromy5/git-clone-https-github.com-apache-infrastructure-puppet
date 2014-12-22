class pam::install::centos::65 (
) {

  file { '/etc/pam.d/':
    ensure   => present, 
    source   => "puppet:///modules/pam/${asfosname}/${asfosrelease}",
    recurse  => true,
    owner    => 'root',
    group    => 'root',
    mode     => '755',
  }
}
