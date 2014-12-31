#/etc/puppet/modules/orthrus/manifests/init.pp

class orthrus {

  case $asfosname {
    ubuntu: {
      $repo_resource = Apt::Source['asf_internal']
      $ortpasswd_path = '/usr/local/bin/ortpasswd'
    }
    centos: {
      $repo_resource = Yumrepo['asf_internal']
      $ortpasswd_path = '/usr/bin/ortpasswd'
    }
    default: {
    }
  }

  package { 'orthrus':
    ensure  => present,
    require => $repo_resource,
  }

  exec { 'setuid-ortpasswd':
    command => "chmod u+s ${ortpasswd_path}",
    unless  => "test -u ${ortpasswd_path}",
    onlyif  => "test -f ${ortpasswd_path}",
    path    => ['/bin', '/usr/bin'],
    require => Package['orthrus'],
  }
}
