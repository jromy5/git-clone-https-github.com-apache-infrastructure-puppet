#/etc/puppet/modules/mx_asf/manifests/init.pp

class mx_asf  (
  ){

     postfix::file { 'incubator_munge_recipient_maps':
       ensure  => present,
       content => '/^(.*)@(.*).incubator.apache.org$/ ${1}@${2}.apache.org',
     }

}
