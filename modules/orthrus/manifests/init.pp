#/etc/puppet/modules/orthrus/manifests/init.pp

class orthrus {

  case $asfosname { 
    ubuntu: {
      package { 'orthrus': 
        ensure  => present,
        require => apt::source['asf_internal'],
      }
    }
    default: {
    }
  }
}
