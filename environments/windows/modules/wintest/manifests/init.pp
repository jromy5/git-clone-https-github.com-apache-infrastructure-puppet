#/etc/puppet/modules/jenkins_node_monitor/manifests/init.pp

class wintest (
){

  file {
    'c:/test.txt':
      ensure => present,
      content => "tacos",
  }
}
