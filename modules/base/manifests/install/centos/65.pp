#/etc/puppet/modules/base/manifests/install/centos/65.pp

class base::install::centos::65 (
  $asfinternalrepo    = '',
  ) {

  yumrepo { 'asf_internal':
    baseurl  => $asfinternalrepo,
    enabled  => 1,
    gpgcheck => 0,
    descr    => 'ASF Internal Yum Repo for CentOS 6',
  }

  file {
    '/usr/local/bin/zsh':
      ensure => link,
      target => '/usr/bin/zsh';
    '/usr/local/bin/bash':
      ensure => link,
      target => '/bin/bash';
  }
}
