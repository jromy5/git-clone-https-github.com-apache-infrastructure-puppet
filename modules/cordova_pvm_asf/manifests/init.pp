# /etc/puppet/modules/cordova_pvm_asf/manifests/init.pp

class cordova_pvm_asf (
  $packages = ['nodejs', 'couchdb'],
) {

  apt::ppa { 'ppa:couchdb/stable':
    ensure => present,
    before => Package['couchdb'],
  }

  -> package { $packages:
    ensure => present,
  }



}
