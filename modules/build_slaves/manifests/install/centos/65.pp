#/etc/puppet/modules/build_slaves/manifests/install/centos/65.pp

class build_slaves::install::centos::65 (
  $erlangrepo    = '',
  $erlangrepokey = ''
) {

  yumrepo { 'erlang-solutions':
    baseurl  => $erlangrepo,
    enabled  => 1,
    gpgcheck => 1,
    descr    => 'Erlang Solutions erlang repo',
    gpgkey   => $erlangrepokey
  }

}
